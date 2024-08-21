-- Various fixes for typst output:
--
-- (1) Fenced divs to environments by known class,
--     or by data-latex-environment attribute.

local utils = require 'pandoc.utils'

local vars = PANDOC_WRITER_OPTIONS.variables or {}

-- NOTE: These assume that something like '#import "@preview/note-me:0.2.1"'
--       is in the preamble:
local known_env_classes = {
    Warning='warning',
    Note='note',
    Tip='tip',
    Important='important',
    Caution='caution',
    Todo='todo',
    Admonition='admonition'}

return {
  {
    Div = function(div)
      -- Handle fenced divs as block environments if (a) the class is known or
      -- (b) the fenced div has the attribute data-typst-wrapper The
      if FORMAT:match('typst') then
        local id, classes, attr = div.identifier, div.classes, div.attributes
        if attr == nil then attr = {} end
        local tfunc_nam = attr['data-typst-func']
        local tfunc_args = attr['data-typst-args']
        if not tfunc_nam then
          for _, cls in pairs(classes) do
            if known_env_classes[cls] then
              tfunc_nam = known_env_classes[cls]
            end
          end
        end
        if tfunc_nam then
          local param = ''
          if tfunc_args then param = '(' .. tfunc_args .. ')' end
          return pandoc.Blocks({
              pandoc.RawBlock(FORMAT, '#' .. tfunc_nam .. param .. '['),
              div,
              pandoc.RawBlock(FORMAT, ']')
          })
        end
      end
    end,
  },
}
