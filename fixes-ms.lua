-- Various fixes for pdroff output:
-- (1) Tasklist items
-- (2) Real underline (not italic)
-- (3) Configurable font in headings

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
      -- Fixes taskitem symbols (by rendering them in the FreeRoman font)
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
      -- (NOTE: Simplisic implementation: '"' inside underline probably causes an error)
      if FORMAT == 'ms' then
        table.insert(ul.content, 1, pandoc.RawInline("ms", '\n.UL "'))
        table.insert(ul.content, pandoc.RawInline("ms", '"\n'))
        return ul.content
      end
    end,
    Header = function(h)
      -- Changes font in headlines based on template variables
      if FORMAT == 'ms' then
        vars = PANDOC_WRITER_OPTIONS.variables or {}
        -- We need to know this so we can switch back to it
        docfam = utils.stringify(vars['fontfamily'] or '')
        hfam = utils.stringify(vars['heading-fontfam'] or '')
        lvl = tonumber(utils.stringify(vars['heading-fontfam-max-level'] or '3'))
        if #docfam > 0 and #hfam > 0 and h.level <= lvl then
          return pandoc.Blocks({
             pandoc.RawBlock('ms', '.ds FAM ' .. hfam),
             h,
             pandoc.RawBlock('ms', '.ds FAM ' .. docfam)
          })
        end
      end
    end,
  },
}
