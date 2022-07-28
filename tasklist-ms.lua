local utils = require 'pandoc.utils'

t_done = "☒"
t_todo = "☐"
t_fix = {}
t_fix[t_done] = '\\f[FSerR]' .. t_done .. '\\f[R]'
t_fix[t_todo] = '\\f[FSerR]' .. t_todo .. '\\f[R]'

function is_taskitem(it)
  if not (it.t == 'Plain' and #(it.content) > 0) then
    return false
  end
  sym = utils.stringify(it.content[1])
  return (sym == t_done or sym == t_todo)
end

function fix_taskitem(item)
  sym = utils.stringify(item.content[1])
  item.content[1] = pandoc.RawInline("ms", t_fix[sym])
  return item
end

return {
  {
    BulletList = function(bl)
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
  },
}
