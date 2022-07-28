local utils = require 'pandoc.utils'

t_done = "☒"
t_todo = "☐"

function is_taskitem(it)
  if not (it.t == 'Plain' and #(it.content) > 0) then
    return false
  end
  sym = utils.stringify(it.content[1])
  return (sym == t_done or sym == t_todo)
end

function fix_taskitem(item)
  sym = utils.stringify(item.content[1])
  item.content[1] = pandoc.RawInline("ms", '\\f[FSerR]' .. sym .. '\\f[R]')
  return item
end

return {
  {
    BulletList = function(bl)
      -- Fixes taskitem symbols (uses the FreeRoman font)
      if FORMAT == 'ms' then
        return bl:walk {
          Plain = function(el)
            if is_taskitem(el) then
              return fix_taskitem(el)
            end
          end
        }
      end
    end,
    Underline = function(ul)
      -- Makes underline really underlined, not italic
      -- (NOTE: '"' inside underline causes error)
      if FORMAT == 'ms' then
        table.insert(ul.content, 1, pandoc.RawInline("ms", '\n.UL "'))
        table.insert(ul.content, pandoc.RawInline("ms", '"\n'))
        return ul.content
      end
    end,
    Header = function(h)
      -- Changes font in headlines based on variables for the output.
      if FORMAT == 'ms' then
        vars = PANDOC_WRITER_OPTIONS.variables or {}
        -- We need to know this so we can switch back to it
        docfam = utils.stringify(vars['fontfamily'] or '')
        hfam = utils.stringify(vars['heading-fontfam'] or '')
        lvl = tonumber(utils.stringify(vars['heading-fontfam-max-level'] or '3'))
        if #docfam > 0 and #hfam > 0 and h.level <= lvl then
          -- Renders headings up to level lvl in this font
          table.insert(h.content, 1, pandoc.RawInline("ms", ".fam " .. hfam .. "\n"))
          table.insert(h.content, pandoc.RawInline("ms", "\n.fam " .. docfam .. "\n"))
          return pandoc.Header(h.level, h.content, h.attr)
        end
      end
    end,
  },
}
