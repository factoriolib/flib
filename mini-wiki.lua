local flib_mini_wiki = {}

-- if in data stage, load prototypes and nothing else
if not script and not data.raw["gui-style"]["default"].flib_mw_pages_scroll_pane then
  require("__flib__.prototypes.mini-wiki")
  return
end

return flib_mini_wiki