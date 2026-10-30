-- pandoc Lua filter for the PDF: each stage (level-2 heading) starts on a new
-- page, and every lower heading demands room for itself plus several table
-- rows, so a heading is never orphaned at the foot of a page.
local first_stage = true

function Header(el)
  if el.level == 2 then
    if first_stage then
      first_stage = false
      return el
    end
    return { pandoc.RawBlock('latex', '\\clearpage'), el }
  elseif el.level == 3 then
    return { pandoc.RawBlock('latex', '\\needspace{14\\baselineskip}'), el }
  elseif el.level == 4 then
    return { pandoc.RawBlock('latex', '\\needspace{12\\baselineskip}'), el }
  end
end
