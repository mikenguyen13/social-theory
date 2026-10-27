-- tools/callouts.lua -- print rendering for the book's callout boxes and
-- house-style punctuation in the LaTeX (PDF) edition.
--  * Divs with a callout class (theory-card, business-case, ...) become
--    tcolorbox environments defined in preamble.tex.
--  * Any en dash, em dash, or semicolon that reaches plain text (for example
--    from the bibliography) is replaced, matching the online edition.

local boxes = {
  ["theory-card"] = "theorycard", ["business-case"] = "businesscase",
  ["research-toolkit"] = "researchtoolkit", ["pitfall"] = "pitfallbox",
  ["key-takeaways"] = "keytakeaways", ["try-it"] = "tryit",
  ["definition"] = "definitionbox", ["debate"] = "debatebox",
}

function Div(el)
  if not FORMAT:match("latex") then return nil end
  for _, cls in ipairs(el.classes) do
    local env = boxes[cls]
    if env then
      table.insert(el.content, 1, pandoc.RawBlock("latex", "\\begin{" .. env .. "}"))
      table.insert(el.content, pandoc.RawBlock("latex", "\\end{" .. env .. "}"))
      return el
    end
  end
  return nil
end

function Str(el)
  if not FORMAT:match("latex") then return nil end
  local t = el.text
  t = t:gsub("(%d)\u{2013}(%d)", "%1-%2")
  t = t:gsub("\u{2013}", "-")
  t = t:gsub("\u{2014}", ", ")
  t = t:gsub(";", ",")
  if t ~= el.text then return pandoc.Str(t) end
  return nil
end
