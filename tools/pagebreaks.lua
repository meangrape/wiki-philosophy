-- pandoc Lua filter for the PDF. Headings: a stage (level 1), a rule
-- (level 2) or a leaf (level 3) demands room for itself plus several
-- table rows, so a heading is never orphaned at the foot of a page.
-- A "note" div (the parenthetical the converter lifts out of a leaf
-- heading) is set in footnotesize, tight under its heading.

function Header(el)
  if el.level == 1 then
    return { pandoc.RawBlock('latex', '\\Needspace*{16\\baselineskip}'), el }
  elseif el.level == 2 then
    return { pandoc.RawBlock('latex', '\\Needspace*{14\\baselineskip}'), el }
  elseif el.level == 3 then
    return { pandoc.RawBlock('latex', '\\Needspace*{12\\baselineskip}'), el }
  end
end

function Div(el)
  if el.classes:includes('note') then
    local blocks = { pandoc.RawBlock('latex', '\\vspace{-0.5\\baselineskip}\\begingroup\\footnotesize') }
    for _, b in ipairs(el.content) do blocks[#blocks + 1] = b end
    blocks[#blocks + 1] = pandoc.RawBlock('latex', '\\endgroup')
    return blocks
  end
end
