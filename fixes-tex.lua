-- Various fixes for LaTeX output:
--
-- (1) Fenced divs to environments by known class,
--     or by data-latex-environment attribute.
-- (2) H6 support

local utils = require 'pandoc.utils'

local vars = PANDOC_WRITER_OPTIONS.variables or {}

local known_env_classes = {Warning=true}

return {
  {
    Div = function(div)
      -- Handle fenced divs as block environments if (a) the class is known or
      -- (b) the fenced div has the attribute data-latex-environment. The
      -- attribute data-latex-env-param can contain arguments/settings for the
      -- environment.
      if FORMAT:match('tex$') then
        local id, classes, attr = div.identifier, div.classes, div.attributes
        if attr == nil then attr = {} end
        local envconf = attr['data-latex-env-param']
        local envnam = attr['data-latex-environment']
        if not envnam then
          for _, cls in pairs(classes) do
            if known_env_classes[cls] then
              envnam = cls
            end
          end
        end
        if envnam then
          local param = ''
          if envconf then param = '[' .. envconf .. ']' end
          return pandoc.Blocks({
              pandoc.RawBlock(FORMAT, '\\begin{' .. envnam .. '}' .. param),
              div,
              pandoc.RawBlock(FORMAT, '\\end{' .. envnam .. '}')
          })
        end
      end
    end,
    Header = function(h)
      -- Display heading level 6 as a noindent paragraph with small type and in bold.
      if FORMAT:match('tex$') and h.level == 6  then
        table.insert(h.content, 1, pandoc.RawInline(
                       FORMAT,
                       '{\\vspace{.5\\baselineskip}\\footnotesize\\noindent\\bfseries '))
        table.insert(h.content, pandoc.RawInline(FORMAT, ' }'))
        return h
      end
    end,
  },
}
