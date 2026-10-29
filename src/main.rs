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

const DEFAULT_DUMP: &str = "enwiki-20261001-pages-articles-multistream.xml.bz2";
const DEFAULT_OUTPUT_CSV: &str = "wiki_edges.csv";
/// bzip2 streams per work unit. Each stream holds 100 pages (~0.3-1 MB
/// compressed), so a batch is a few MB of input and ~20 MB of XML.
const STREAMS_PER_BATCH: usize = 8;
/// Cap on link-less pages sampled into `$NULL_SAMPLE` (title + text head).
const NULL_SAMPLE_CAP: usize = 3000;

struct Row {
    title: String,
    /// First link under the strict rule (parentheses skipped).
    target: Option<String>,
    /// First link when parenthesized links count too.
    target_paren: Option<String>,
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
    Some(s.len())
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
            let p = prefix.trim().to_ascii_lowercase();
            NON_ARTICLE_PREFIXES.contains(&p.as_str())
                || ((2..=12).contains(&p.len())
                    && p.bytes().all(|c| c.is_ascii_lowercase() || c == b'-'))
        }
    }
}

/// Canonical page-title form: anchor stripped, whitespace collapsed to `_`,
/// first letter upper-cased (enwiki is `case="first-letter"`).
fn normalize_title(raw: &str) -> Option<String> {
    // MediaWiki decodes HTML entities in link targets; the XML layer only
    // decoded the XML ones. A target still holding markup is not a title.
    let decoded = raw
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace("&quot;", "\"")
        .replace("&#39;", "'");
    if decoded.contains(['{', '}', '<', '>', '[', ']', '|']) {
        return None;
    }
    let no_anchor = decoded.split('#').next().unwrap_or("");
    let joined = no_anchor.split_whitespace().collect::<Vec<_>>().join("_");
    let trimmed = joined.trim_matches('_');
    let mut chars = trimmed.chars();
    let first = chars.next()?;
    let mut out = String::with_capacity(trimmed.len());
    out.extend(first.to_uppercase());
    out.push_str(chars.as_str());
    Some(out)
}

/// First `[[wikilink]]` in the body under two rules, found in one pass:
/// strict skips links inside parentheses, lenient takes them. Both skip
/// italics and braces (templates `{{ }}` and tables `{| |}`), and skip
/// namespaced links together with their captions, e.g.
/// `[[File:x.jpg|thumb|[[Link]]]]`. Comments and `<ref>`-style tags are
/// skipped in the same pass. Returns (strict, lenient).
fn find_first_links(text: &str) -> (Option<String>, Option<String>) {
    let b = text.as_bytes();
    let n = b.len();
    let mut i = 0;
    let mut depth_paren = 0u32;
    let mut depth_curly = 0u32;
    let mut italic = false;
    let mut lenient: Option<String> = None;

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

                if depth_curly == 0 && !italic {
                    if let Some(t) = normalize_title(target) {
                        if depth_paren == 0 {
                            let lenient = lenient.unwrap_or_else(|| t.clone());
                            return (Some(t), Some(lenient));
                        }
                        if lenient.is_none() {
                            lenient = Some(t);
                        }
                    }
                }
                i = j;
                continue;
            }
            _ => {}
        }
        i += 1;
    }
    (None, lenient)
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
                        let (target, target_paren) = match redirect_to.take() {
                            Some(r) => (Some(r.clone()), Some(r)),
                            None => find_first_links(&text),
                        };
                        let snippet = if sample_nulls && target.is_none() && !is_redirect {
                            Some(head_chars(text.trim_start(), 300))
                        } else {
                            None
                        };
                        rows.push(Row {
                            title: std::mem::take(&mut title),
                            target,
                            target_paren,
                            is_redirect,
                            snippet,
                        });
                    }
                }
                _ => {}
            },
            Ok(Event::Eof) => break,
            Err(e) => {
                eprintln!("XML warning (fragment skipped from here): {:?}", e);
                break;
            }
            _ => {}
        }
        buf.clear();
    }
    rows
}

/// Byte offsets of every bzip2 stream header (`BZh<1-9>` + block magic
/// `1AY&SY`) in the mapped file. Each multistream chunk is its own stream.
fn stream_starts(data: &[u8]) -> Vec<usize> {
    let mut starts = Vec::with_capacity(data.len() / 400_000);
    for pos in memmem::find_iter(data, b"1AY&SY") {
        if pos >= 4 && &data[pos - 4..pos - 1] == b"BZh" && data[pos - 1].is_ascii_digit() {
            starts.push(pos - 4);
        }
    }
    starts
}

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
            let (strict, lenient) = find_first_links(&text);
            println!(
                "{}\tstrict={}\tparen={}",
                path,
                strict.unwrap_or_default(),
                lenient.unwrap_or_default()
            );
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
    let out_file = File::create(&output_csv)?;
    let mut writer = BufWriter::with_capacity(4 << 20, out_file);
    writeln!(writer, "title,target_title,paren_target_title,is_redirect")?;

    let mut null_writer = match &null_sample_path {
        Some(p) => Some(BufWriter::new(File::create(p)?)),
        None => None,
    };
    let sample_nulls = null_writer.is_some();

    // (batch index, byte range) of STREAMS_PER_BATCH consecutive streams.
    let (tx_batches, rx_batches) = bounded::<(usize, usize, usize)>(64);
    let (tx_results, rx_results) = bounded::<(usize, Vec<Row>)>(64);

    // THREAD 1: scan the mapped file for stream headers and hand out ranges.
    let scanner = std::thread::spawn(move || {
        let starts = stream_starts(data);
        println!("Found {} bzip2 streams in {:.1}s", starts.len(), start_time.elapsed().as_secs_f64());
        // MAX_BATCHES=<n> stops after n batches, for benchmarking.
        let max_batches: usize = std::env::var("MAX_BATCHES").ok().and_then(|v| v.parse().ok()).unwrap_or(usize::MAX);
        let mut idx = 0;
        for group in starts.chunks(STREAMS_PER_BATCH).take(max_batches) {
            let begin = group[0];
            let end = starts
                .get(idx * STREAMS_PER_BATCH + group.len())
                .copied()
                .unwrap_or(data.len());
            if tx_batches.send((idx, begin, end)).is_err() {
                break;
            }
            idx += 1;
        }
    });

    // THREADS 2-N: decompress + parse each batch on the rayon pool.
    let workers = std::thread::spawn(move || {
        rx_batches.into_iter().par_bridge().for_each(|(idx, begin, end)| {
            let slice = &data[begin..end];
            let mut xml = Vec::with_capacity(slice.len() * 8);
            if let Err(e) = MultiBzDecoder::new(slice).read_to_end(&mut xml) {
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
            for row in rows {
                n_rows += 1;
                if row.is_redirect {
                    n_redirects += 1;
                }
                let t = csv_field(&row.title);
                let flag = if row.is_redirect { 't' } else { 'f' };
                if row.target.is_none() {
                    n_null += 1;
                }
                let strict = row.target.as_deref().map(csv_field).unwrap_or_default();
                let paren = row.target_paren.as_deref().map(csv_field).unwrap_or_default();
                writeln!(writer, "{},{},{},{}", t, strict, paren, flag)?;
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

    writer.flush()?;
    if let Some(w) = null_writer.as_mut() {
        w.flush()?;
    }
    scanner.join().map_err(|_| "scanner thread panicked")?;
    workers.join().map_err(|_| "worker thread panicked")?;

    println!(
        "\nDone in {:.1?}: {} rows ({} redirects, {} without a target) written to {}",
        start_time.elapsed(),
        n_rows,
        n_redirects,
        n_null,
        output_csv
    );
    Ok(())
}
