use bzip2::read::MultiBzDecoder;
use crossbeam_channel::bounded;
use memchr::{memchr, memmem};
use memmap2::Mmap;
use quick_xml::Reader;
use quick_xml::events::Event;
use rayon::prelude::*;
use std::borrow::Cow;
use std::collections::BTreeMap;
use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Instant;

static PAGES_PROCESSED: AtomicU64 = AtomicU64::new(0);
static BYTES_CONSUMED: AtomicU64 = AtomicU64::new(0);
/// Batches whose XML stopped parsing early / whose bzip2 data failed to
/// decode. Either one means the CSV is incomplete, so `main` fails.
static XML_ERRORS: AtomicU64 = AtomicU64::new(0);
static BZ_ERRORS: AtomicU64 = AtomicU64::new(0);

const DEFAULT_DUMP: &str = "enwiki-20261001-pages-articles-multistream.xml.bz2";
const DEFAULT_OUTPUT_CSV: &str = "wiki_edges.csv";
/// bzip2 streams per work unit. Each stream holds 100 pages (~0.3-1 MB
/// compressed), so a batch is a few MB of input and ~20 MB of XML.
const STREAMS_PER_BATCH: usize = 8;
/// Cap on link-less pages sampled into `$NULL_SAMPLE` (title + text head).
const NULL_SAMPLE_CAP: usize = 3000;

/// Link contexts a rule may exclude, as bits of a candidate's context mask.
const IN_PAREN: u8 = 1;
const IN_ITALIC: u8 = 2;
const IN_TEMPLATE: u8 = 4;

/// The rules written to the CSV, as the set of contexts each one excludes.
/// Order matches the CSV columns after `title`.
const RULES: &[(&str, u8)] = &[
    ("strict", IN_PAREN | IN_ITALIC | IN_TEMPLATE), // Wikipedia's strict rule
    ("parens_ok", IN_ITALIC | IN_TEMPLATE),         // parenthesized links count
    ("skip_parens", IN_PAREN),                      // only parenthesized links skipped
    ("skip_italics", IN_ITALIC),                    // only italicized links skipped
    ("loose", IN_TEMPLATE),                         // only template links skipped: Wikipedia's loose rule
];

struct Row {
    title: String,
    /// First link under each rule in `RULES`, same order.
    targets: Vec<Option<String>>,
    is_redirect: bool,
    /// Head of the cleaned wikitext, only for link-less pages when sampling.
    snippet: Option<String>,
}

/// Namespace and interwiki prefixes whose links are never article edges.
const NON_ARTICLE_PREFIXES: &[&str] = &[
    "media", "special", "talk", "user", "user talk", "wikipedia", "wikipedia talk", "wp",
    "project", "project talk", "file", "file talk", "image", "image talk", "mediawiki",
    "mediawiki talk", "template", "template talk", "help", "help talk", "category",
    "category talk", "portal", "portal talk", "draft", "draft talk", "timedtext",
    "timedtext talk", "module", "module talk", "event", "event talk", "gadget",
    "gadget definition", "book", "wikt", "wiktionary", "commons", "c", "meta", "m", "s",
    "wikisource", "q", "wikiquote", "b", "wikibooks", "v", "wikiversity", "n", "wikinews",
    "d", "wikidata", "voy", "wikivoyage", "species", "mw", "incubator", "foundation", "wmf",
];

/// Markup that never carries a counting link: HTML comments and the
/// contents of ref / nowiki / math / gallery / code-like extension tags.
const SKIP_TAGS: &[&[u8]] = &[
    b"ref", b"nowiki", b"math", b"chem", b"gallery", b"pre", b"code", b"syntaxhighlight",
    b"source", b"timeline", b"imagemap", b"score", b"hiero", b"mapframe", b"maplink",
];

/// `s` starts with `<`. If it opens a comment or a skip-tag, return how many
/// bytes to jump to get past the whole element (to end of input when it is
/// unterminated). Otherwise None.
fn markup_skip_len(s: &[u8]) -> Option<usize> {
    if s.starts_with(b"<!--") {
        return Some(memmem::find(&s[4..], b"-->").map_or(s.len(), |p| 4 + p + 3));
    }
    let name_end = s[1..]
        .iter()
        .position(|c| !c.is_ascii_alphanumeric())
        .map_or(s.len(), |p| p + 1);
    let name = &s[1..name_end];
    if name.is_empty() || !SKIP_TAGS.iter().any(|t| t.eq_ignore_ascii_case(name)) {
        return None;
    }
    let gt = name_end + memchr(b'>', &s[name_end..])?;
    if s[gt - 1] == b'/' {
        return Some(gt + 1); // self-closing, e.g. <ref name="x"/>
    }
    let mut j = gt + 1;
    while let Some(p) = memchr(b'<', &s[j..]) {
        let k = j + p;
        if k + 2 + name.len() <= s.len()
            && s[k + 1] == b'/'
            && s[k + 2..k + 2 + name.len()].eq_ignore_ascii_case(name)
        {
            return Some(memchr(b'>', &s[k..]).map_or(s.len(), |q| k + q + 1));
        }
        j = k + 1;
    }
    // Unclosed: MediaWiki renders the opener as literal text, so keep scanning.
    None
}

/// True when a link target points outside the main article namespace
/// (`File:`, `Category:`, `wikt:`, `fr:`, a leading `:`...). A colon alone is
/// not enough: "Dune: Part Two" is an article.
fn is_namespaced(target: &str) -> bool {
    let t = target.trim_start();
    if t.starts_with(':') {
        return true;
    }
    match t.split_once(':') {
        None => false,
        Some((prefix, _)) => {
            // The language-code heuristic looks at the prefix as written:
            // interwiki codes are lower-case ("fr:", "zh-yue:"), titles are not.
            let raw = prefix.trim();
            let p = raw.to_ascii_lowercase();
            NON_ARTICLE_PREFIXES.contains(&p.as_str())
                || ((2..=12).contains(&raw.len())
                    && raw.bytes().all(|c| c.is_ascii_lowercase() || c == b'-'))
        }
    }
}

/// The character an HTML entity body (between `&` and `;`) stands for.
fn decode_entity(name: &str) -> Option<char> {
    if let Some(num) = name.strip_prefix('#') {
        let code = match num.strip_prefix(['x', 'X']) {
            Some(hex) => u32::from_str_radix(hex, 16).ok()?,
            None => num.parse().ok()?,
        };
        return char::from_u32(code);
    }
    Some(match name {
        "amp" => '&',
        "apos" => '\'',
        "gt" => '>',
        "lt" => '<',
        "mdash" => '—',
        "nbsp" => ' ',
        "ndash" => '–',
        "quot" => '"',
        _ => return None,
    })
}

/// Decode HTML entities in one left-to-right pass, so `&amp;quot;` becomes
/// `&quot;` rather than `"`. Unknown or malformed references stay literal.
fn decode_entities(s: &str) -> Cow<'_, str> {
    if !s.contains('&') {
        return Cow::Borrowed(s);
    }
    let mut out = String::with_capacity(s.len());
    let mut rest = s;
    while let Some(p) = rest.find('&') {
        out.push_str(&rest[..p]);
        let after = &rest[p + 1..];
        // Longest supported body is "#x10FFFF" / "mdash"; 10 bytes is ample.
        let semi = after.bytes().take(10).position(|c| c == b';');
        match semi.and_then(|k| decode_entity(&after[..k]).map(|c| (c, k))) {
            Some((c, k)) => {
                out.push(c);
                rest = &after[k + 1..];
            }
            None => {
                out.push('&');
                rest = after;
            }
        }
    }
    out.push_str(rest);
    Cow::Owned(out)
}

/// Canonical page-title form: anchor stripped, whitespace collapsed to `_`,
/// first letter upper-cased (enwiki is `case="first-letter"`).
fn normalize_title(raw: &str) -> Option<String> {
    // MediaWiki decodes HTML entities in link targets; the XML layer only
    // decoded the XML ones. A target still holding markup is not a title.
    let decoded = decode_entities(raw);
    if decoded.contains(['{', '}', '<', '>', '[', ']', '|']) {
        return None;
    }
    let no_anchor = decoded.split('#').next().unwrap_or("");
    let joined = no_anchor
        .split(|c: char| c.is_whitespace() || c == '_')
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("_");
    let trimmed = joined.trim_matches('_');
    let mut chars = trimmed.chars();
    let first = chars.next()?;
    let mut out = String::with_capacity(trimmed.len());
    out.extend(first.to_uppercase());
    out.push_str(chars.as_str());
    Some(out)
}

/// First `[[wikilink]]` in the body under every rule in `RULES`, found in one
/// pass. Each candidate link carries a context mask (inside parentheses,
/// italics, a template or table); a rule accepts the first candidate that
/// is in none of the contexts it excludes. Namespaced links are skipped
/// together with their captions, e.g. `[[File:x.jpg|thumb|[[Link]]]]`, and
/// comments and `<ref>`-style tags are skipped as units.
fn find_first_links(text: &str) -> Vec<Option<String>> {
    let b = text.as_bytes();
    let n = b.len();
    let mut i = 0;
    let mut depth_paren = 0u32;
    let mut depth_curly = 0u32;
    let mut italic = false;
    let mut found: Vec<Option<String>> = vec![None; RULES.len()];
    let mut remaining = RULES.len();

    while i < n {
        match b[i] {
            b'<' => {
                if let Some(skip) = markup_skip_len(&b[i..]) {
                    i += skip;
                    continue;
                }
            }
            // Parentheses are only meaningful in prose. Inside templates
            // they appear unbalanced all the time (file names, coordinates,
            // footnotes), and a stray '(' would hide every later link.
            b'(' if depth_curly == 0 => depth_paren += 1,
            b')' if depth_curly == 0 => depth_paren = depth_paren.saturating_sub(1),
            // MediaWiki closes italics at end of line, and a prose
            // parenthetical never spans a line break.
            b'\n' => {
                depth_paren = 0;
                italic = false;
            }
            b'{' => depth_curly += 1,
            b'}' => depth_curly = depth_curly.saturating_sub(1),
            // '' toggles italic, ''' bold, '''' = apostrophe + bold,
            // ''''' toggles both.
            b'\'' => {
                let mut run = 1;
                while i + run < n && b[i + run] == b'\'' {
                    run += 1;
                }
                if run == 2 || run >= 5 {
                    italic = !italic;
                }
                i += run;
                continue;
            }
            b'[' if i + 1 < n && b[i + 1] == b'[' => {
                let start = i + 2;
                let mut j = start;
                while j < n && !matches!(b[j], b'|' | b']' | b'[' | b'\n') {
                    j += 1;
                }
                // Only `|` or `]]` closes a target; `[[Foo\n`, `[[Foo]` and
                // `[[Foo[[Bar]]` are literal text. Captions may span lines.
                let closed = j < n
                    && (b[j] == b'|' || (b[j] == b']' && j + 1 < n && b[j + 1] == b']'));
                if !closed {
                    i += 2;
                    continue;
                }
                let target = &text[start..j];

                if is_namespaced(target) {
                    // Skip the whole link including nested links in its caption.
                    let mut depth = 1u32;
                    let mut k = j;
                    while k + 1 < n && depth > 0 {
                        if b[k] == b'[' && b[k + 1] == b'[' {
                            depth += 1;
                            k += 2;
                        } else if b[k] == b']' && b[k + 1] == b']' {
                            depth -= 1;
                            k += 2;
                        } else {
                            k += 1;
                        }
                    }
                    i = k;
                    continue;
                }

                if let Some(t) = normalize_title(target) {
                    let mask = (depth_paren > 0) as u8 * IN_PAREN
                        | italic as u8 * IN_ITALIC
                        | (depth_curly > 0) as u8 * IN_TEMPLATE;
                    for (slot, (_, excluded)) in found.iter_mut().zip(RULES) {
                        if slot.is_none() && mask & excluded == 0 {
                            *slot = Some(t.clone());
                            remaining -= 1;
                        }
                    }
                    if remaining == 0 {
                        return found;
                    }
                }
                i = j;
                continue;
            }
            _ => {}
        }
        i += 1;
    }
    found
}

/// RFC 4180 quoting so Postgres `COPY ... CSV` accepts titles such as
/// `Paris,_Texas` or `"Weird_Al"_Yankovic`.
fn csv_field(s: &str) -> Cow<'_, str> {
    if s.contains([',', '"', '\n', '\r']) {
        Cow::Owned(format!("\"{}\"", s.replace('"', "\"\"")))
    } else {
        Cow::Borrowed(s)
    }
}

fn is_redirect_text(text: &str) -> bool {
    let t = text.trim_start();
    t.len() >= 9 && t.as_bytes()[..9].eq_ignore_ascii_case(b"#redirect")
}

fn head_chars(s: &str, max: usize) -> String {
    s.chars().take(max).collect::<String>().replace(['\n', '\r', '\t'], " ")
}

enum CurrentElement {
    Title,
    Ns,
    Text,
    None,
}

/// Parse a concatenation of `<page>` elements (one or more decompressed
/// bzip2 streams) and compute the first-link edge of every ns-0 page.
fn process_xml(xml: &[u8], sample_nulls: bool) -> Vec<Row> {
    let mut rows = Vec::with_capacity(STREAMS_PER_BATCH * 100);
    let mut reader = Reader::from_reader(xml);
    reader.check_end_names(false);
    let mut buf = Vec::with_capacity(256 * 1024);

    let mut current = CurrentElement::None;
    let mut title = String::new();
    let mut ns: i64 = -1;
    let mut redirect_to: Option<String> = None;
    let mut text = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => match e.name().as_ref() {
                b"page" => {
                    title.clear();
                    ns = -1;
                    redirect_to = None;
                    text.clear();
                }
                b"title" => current = CurrentElement::Title,
                b"ns" => current = CurrentElement::Ns,
                b"text" => current = CurrentElement::Text,
                _ => {}
            },
            Ok(Event::Empty(e)) if e.name().as_ref() == b"redirect" => {
                for attr in e.attributes().flatten() {
                    if attr.key.as_ref() == b"title" {
                        if let Ok(v) = attr.unescape_value() {
                            // A redirect into Category:/Template:/... is not an article edge.
                            if !is_namespaced(&v) {
                                redirect_to = normalize_title(&v);
                            }
                        }
                    }
                }
            }
            Ok(Event::Text(e)) => {
                if let Ok(decoded) = e.unescape() {
                    match current {
                        CurrentElement::Title => title = decoded.trim().replace(' ', "_"),
                        CurrentElement::Ns => ns = decoded.trim().parse().unwrap_or(-1),
                        CurrentElement::Text => {
                            if ns == 0 {
                                if text.is_empty() {
                                    text = decoded.into_owned();
                                } else {
                                    text.push_str(&decoded);
                                }
                            }
                        }
                        CurrentElement::None => {}
                    }
                }
            }
            Ok(Event::End(e)) => match e.name().as_ref() {
                b"title" | b"ns" | b"text" => current = CurrentElement::None,
                b"page" => {
                    if ns == 0 && !title.is_empty() {
                        PAGES_PROCESSED.fetch_add(1, Ordering::Relaxed);
                        let is_redirect = redirect_to.is_some() || is_redirect_text(&text);
                        let targets = match redirect_to.take() {
                            Some(r) => vec![Some(r); RULES.len()],
                            None => find_first_links(&text),
                        };
                        let snippet = if sample_nulls && targets[0].is_none() && !is_redirect {
                            Some(head_chars(text.trim_start(), 300))
                        } else {
                            None
                        };
                        rows.push(Row {
                            title: std::mem::take(&mut title),
                            targets,
                            is_redirect,
                            snippet,
                        });
                    }
                }
                _ => {}
            },
            Ok(Event::Eof) => break,
            Err(e) => {
                XML_ERRORS.fetch_add(1, Ordering::Relaxed);
                eprintln!("XML error (rest of batch skipped): {:?}", e);
                break;
            }
            _ => {}
        }
        buf.clear();
    }
    rows
}

/// Byte offset of the bzip2 stream header (`BZh<1-9>`) when block magic
/// `1AY&SY` found at `pos` is the first block of a stream.
fn stream_start_at(data: &[u8], pos: usize) -> Option<usize> {
    let h = pos.checked_sub(4)?;
    (data.get(h..pos - 1)? == b"BZh" && data[pos - 1].is_ascii_digit()).then_some(h)
}

/// A real multistream dump holds a siteinfo stream plus one stream per 100
/// pages (well under 16 MB each). Fewer streams than that means a
/// single-stream or foreign file, whose one batch would span the whole input.
fn check_multistream(n_streams: usize, len: usize) -> Result<(), String> {
    if n_streams < 2 || n_streams < len / (16 << 20) {
        return Err(format!("not a multistream dump ({n_streams} streams in {len} bytes)"));
    }
    Ok(())
}

/// Cap on the per-batch decompression buffer reservation; it still grows
/// past this if a batch really is larger.
const MAX_XML_PREALLOC: usize = 256 << 20;

/// Most batches handed out but not yet written, which bounds the writer's
/// reorder buffer. A batch of rows is ~800 titles plus targets (well under
/// 1 MB), so the buffer stays in the tens of MB; 128 is several times the
/// worker count, so workers never starve on credit in steady state.
const BATCH_WINDOW: usize = 128;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let start_time = Instant::now();
    let args: Vec<String> = std::env::args().collect();
    let target_path = if args.len() > 1 { &args[1] } else { DEFAULT_DUMP };
    let null_sample_path = std::env::var("NULL_SAMPLE").ok();

    // Debug: `wiki-philosophy --first-link a.wikitext b.wikitext` prints the
    // link the scanner would choose for each file.
    if args.get(1).map(String::as_str) == Some("--first-link") {
        for path in &args[2..] {
            let text = std::fs::read_to_string(path)?;
            let found = find_first_links(&text);
            let cols: Vec<String> = RULES
                .iter()
                .zip(&found)
                .map(|((name, _), t)| format!("{}={}", name, t.clone().unwrap_or_default()))
                .collect();
            println!("{}\t{}", path, cols.join("\t"));
        }
        return Ok(());
    }

    println!("Target Path: {}", target_path);
    println!("Worker threads: {}", rayon::current_num_threads());

    let file = match File::open(target_path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Error opening file '{}': {}", target_path, e);
            std::process::exit(1);
        }
    };
    // SAFETY: the dump is read-only for the lifetime of this process.
    let mmap: &'static Mmap = Box::leak(Box::new(unsafe { Mmap::map(&file)? }));
    let data: &'static [u8] = &mmap[..];
    let total_bytes = data.len() as u64;

    let output_csv = std::env::var("OUTPUT_CSV").unwrap_or_else(|_| DEFAULT_OUTPUT_CSV.to_string());
    // Written under a temporary name and renamed only once the run is known
    // complete, so an abort never leaves a truncated CSV at `output_csv`.
    let output_tmp = format!("{output_csv}.tmp");
    let out_file = File::create(&output_tmp)?;
    let mut writer = BufWriter::with_capacity(4 << 20, out_file);
    let header: Vec<String> = RULES.iter().map(|(name, _)| format!("{}_target_title", name)).collect();
    writeln!(writer, "title,{},is_redirect", header.join(","))?;

    let mut null_writer = match &null_sample_path {
        Some(p) => Some(BufWriter::new(File::create(format!("{p}.tmp"))?)),
        None => None,
    };
    let sample_nulls = null_writer.is_some();

    // (batch index, byte range) of STREAMS_PER_BATCH consecutive streams.
    let (tx_batches, rx_batches) = bounded::<(usize, usize, usize)>(64);
    let (tx_results, rx_results) = bounded::<(usize, Vec<Row>)>(64);
    // Credit window: the scanner takes a token before handing out a batch and
    // the writer returns one per batch written, so at most BATCH_WINDOW
    // batches are in flight and the reorder buffer `pending` stays bounded
    // even while one slow batch holds up `next_idx`.
    let (tx_credit, rx_credit) = bounded::<()>(BATCH_WINDOW);
    for _ in 0..BATCH_WINDOW {
        tx_credit.try_send(()).map_err(|_| "credit channel full while priming")?;
    }

    // THREAD 1: scan the mapped file for stream headers and hand out ranges.
    // Batch k is sent as soon as the start of batch k+1 is known, so workers
    // begin while the scan is still running.
    // Returns the number of batches sent.
    let scanner = std::thread::spawn(move || -> Result<usize, String> {
        // MAX_BATCHES=<n> stops after n batches, for benchmarking.
        let max_batches: usize = std::env::var("MAX_BATCHES").ok().and_then(|v| v.parse().ok()).unwrap_or(usize::MAX);
        let mut starts: Vec<usize> = Vec::with_capacity(data.len() / 400_000);
        let mut idx = 0;
        for start in memmem::find_iter(data, b"1AY&SY").filter_map(|pos| stream_start_at(data, pos)) {
            starts.push(start);
            if idx >= max_batches {
                break;
            }
            // starts[idx*S] begins batch idx; starts[(idx+1)*S] ends it.
            if starts.len() == (idx + 1) * STREAMS_PER_BATCH + 1 {
                let (begin, end) = (starts[idx * STREAMS_PER_BATCH], start);
                // Either failing means the writer is gone: stop handing out work.
                if rx_credit.recv().is_err() || tx_batches.send((idx, begin, end)).is_err() {
                    return Ok(idx);
                }
                idx += 1;
            }
        }
        if idx >= max_batches {
            return Ok(idx);
        }
        println!("Found {} bzip2 streams in {:.1}s", starts.len(), start_time.elapsed().as_secs_f64());
        check_multistream(starts.len(), data.len())?;
        if let Some(&begin) = starts.get(idx * STREAMS_PER_BATCH)
            && rx_credit.recv().is_ok()
            && tx_batches.send((idx, begin, data.len())).is_ok()
        {
            idx += 1;
        }
        Ok(idx)
    });

    // THREADS 2-N: decompress + parse each batch on the rayon pool.
    let workers = std::thread::spawn(move || {
        rx_batches.into_iter().par_bridge().for_each(|(idx, begin, end)| {
            let slice = &data[begin..end];
            let mut xml = Vec::with_capacity(slice.len().saturating_mul(8).min(MAX_XML_PREALLOC));
            if let Err(e) = MultiBzDecoder::new(slice).read_to_end(&mut xml) {
                BZ_ERRORS.fetch_add(1, Ordering::Relaxed);
                eprintln!("bzip2 error in batch {} ({}..{}): {}", idx, begin, end, e);
            }
            let rows = process_xml(&xml, sample_nulls);
            BYTES_CONSUMED.fetch_add((end - begin) as u64, Ordering::Relaxed);
            let _ = tx_results.send((idx, rows));
        });
    });

    // MAIN THREAD: write batches in input order.
    let mut pending: BTreeMap<usize, Vec<Row>> = BTreeMap::new();
    let mut next_idx = 0usize;
    let mut last_report = Instant::now();
    let mut n_rows = 0u64;
    let mut n_redirects = 0u64;
    let mut n_null = 0u64;
    let mut n_sampled = 0usize;

    for (idx, rows) in rx_results {
        pending.insert(idx, rows);
        while let Some(rows) = pending.remove(&next_idx) {
            next_idx += 1;
            // Never blocks: tokens held + batches in flight == BATCH_WINDOW.
            // Fails only once the scanner has exited, which is harmless.
            let _ = tx_credit.try_send(());
            for row in rows {
                n_rows += 1;
                if row.is_redirect {
                    n_redirects += 1;
                }
                let t = csv_field(&row.title);
                let flag = if row.is_redirect { 't' } else { 'f' };
                if row.targets[0].is_none() {
                    n_null += 1;
                }
                let cols: Vec<Cow<str>> = row
                    .targets
                    .iter()
                    .map(|t| t.as_deref().map(csv_field).unwrap_or_default())
                    .collect();
                writeln!(writer, "{},{},{}", t, cols.join(","), flag)?;
                if let (Some(w), Some(s)) = (null_writer.as_mut(), row.snippet.as_ref()) {
                    if n_sampled < NULL_SAMPLE_CAP {
                        n_sampled += 1;
                        writeln!(w, "{}\t{}", row.title, s)?;
                    }
                }
            }
        }

        if last_report.elapsed().as_secs() >= 3 {
            let pages = PAGES_PROCESSED.load(Ordering::Relaxed);
            let bytes = BYTES_CONSUMED.load(Ordering::Relaxed);
            let elapsed = start_time.elapsed().as_secs_f64();
            println!(
                "{:5.1}% | {} articles | {:.0} articles/s | {:.1} MB/s compressed | {:.0}s",
                bytes as f64 * 100.0 / total_bytes as f64,
                pages,
                pages as f64 / elapsed,
                bytes as f64 / elapsed / 1e6,
                elapsed
            );
            last_report = Instant::now();
        }
    }

    // Close both files before any check so the .tmp contents are complete
    // on disk whatever happens next.
    writer.into_inner().map_err(|e| e.into_error())?.sync_all()?;
    if let Some(w) = null_writer.take() {
        w.into_inner().map_err(|e| e.into_error())?;
    }
    let scanned = scanner.join().map_err(|_| "scanner thread panicked")?;
    workers.join().map_err(|_| "worker thread panicked")?;
    let batches_sent = scanned?;

    let xml_errors = XML_ERRORS.load(Ordering::Relaxed);
    let bz_errors = BZ_ERRORS.load(Ordering::Relaxed);
    println!(
        "\nDone in {:.1?}: {} rows ({} redirects, {} without a target) written to {} \
         ({} bzip2 errors, {} XML errors)",
        start_time.elapsed(),
        n_rows,
        n_redirects,
        n_null,
        output_csv,
        bz_errors,
        xml_errors
    );
    if bz_errors + xml_errors > 0 {
        return Err(format!(
            "{} batches had errors ({bz_errors} bzip2, {xml_errors} XML); {output_tmp} is incomplete",
            bz_errors + xml_errors
        )
        .into());
    }
    if !pending.is_empty() || next_idx != batches_sent {
        return Err(format!(
            "wrote {next_idx} of {batches_sent} batches ({} still pending); {output_tmp} is incomplete",
            pending.len()
        )
        .into());
    }
    std::fs::rename(&output_tmp, &output_csv)?;
    if let Some(p) = &null_sample_path {
        std::fs::rename(format!("{p}.tmp"), p)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn strict(text: &str) -> Option<String> {
        find_first_links(text).into_iter().next().flatten()
    }

    // Card 1
    #[test]
    fn colon_titles_are_articles() {
        for t in ["Dune: Part Two", "Halo: Reach", "Alien: Covenant"] {
            assert!(!is_namespaced(t), "{t}");
        }
    }

    #[test]
    fn namespace_and_interwiki_prefixes_are_namespaced() {
        for t in ["fr:Paris", "File:X.jpg", "wikt:word", ":Category:X"] {
            assert!(is_namespaced(t), "{t}");
        }
    }

    #[test]
    fn colon_title_is_chosen_under_every_rule() {
        let found = find_first_links("See [[Dune: Part Two]] and [[Foo]].");
        assert!(found.iter().all(|t| t.as_deref() == Some("Dune:_Part_Two")), "{found:?}");
    }

    // Card 8
    #[test]
    fn malformed_link_openers_are_literal_text() {
        assert_eq!(strict("[[Foo\n[[Bar]]").as_deref(), Some("Bar"));
        assert_eq!(strict("[[Foo] x [[Bar]]").as_deref(), Some("Bar"));
        assert_eq!(strict("[[Foo[[Bar]]").as_deref(), Some("Bar"));
        assert_eq!(strict("[[Foo]").as_deref(), None);
    }

    #[test]
    fn caption_may_span_lines() {
        assert_eq!(strict("[[Foo|a\nb]] [[Bar]]").as_deref(), Some("Foo"));
    }

    // Card 10
    #[test]
    fn unclosed_skip_tag_is_literal_text() {
        assert_eq!(strict("text <ref>unclosed [[A]] then [[B]]").as_deref(), Some("A"));
        assert_eq!(strict("x <ref>r [[A]]</ref> [[B]]").as_deref(), Some("B"));
        assert_eq!(strict("x <!-- [[A]] [[B]]").as_deref(), None);
    }

    // Card 17
    #[test]
    fn entities_decode_once_left_to_right() {
        assert_eq!(normalize_title("A&amp;quot;B").as_deref(), Some("A&quot;B"));
        assert_eq!(normalize_title("1914&ndash;1918").as_deref(), Some("1914–1918"));
        assert_eq!(normalize_title("O&#39;Brien").as_deref(), Some("O'Brien"));
        assert_eq!(normalize_title("O&#x27;Brien").as_deref(), Some("O'Brien"));
        assert_eq!(normalize_title("AT&T").as_deref(), Some("AT&T"));
        assert_eq!(normalize_title("a&nbsp;b").as_deref(), Some("A_b"));
        assert_eq!(normalize_title("Q&amp;A").as_deref(), Some("Q&A"));
    }

    // Card 27
    #[test]
    fn single_stream_inputs_are_rejected() {
        assert!(check_multistream(1, 40).is_err());
        assert!(check_multistream(0, 0).is_err());
        assert!(check_multistream(3, 64 << 20).is_err());
        assert!(check_multistream(40, 20 << 20).is_ok());
    }

    #[test]
    fn stream_header_detection() {
        let d = b"xxBZh91AY&SYyy";
        assert_eq!(stream_start_at(d, 6), Some(2));
        assert_eq!(stream_start_at(b"Zh91AY&SY", 3), None);
        assert_eq!(stream_start_at(b"BZhx1AY&SY", 4), None);
    }

    // Card 18
    #[test]
    fn mixed_space_underscore_runs_collapse() {
        assert_eq!(normalize_title("Foo__Bar").as_deref(), Some("Foo_Bar"));
        assert_eq!(normalize_title("Foo _Bar").as_deref(), Some("Foo_Bar"));
        assert_eq!(normalize_title(" _foo bar_ ").as_deref(), Some("Foo_bar"));
    }
}
