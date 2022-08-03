-- Various fixes for pdroff output:
-- (1) Tasklist items (now normally handled by the bk.ms template instead)
-- (2) Real underline (not italic)
-- (3) Configurable font in headings

local utils = require 'pandoc.utils'

local t_done = "☒" -- u2612
local t_todo = "☐"  -- u2610

function is_taskitem(it)
  if not (it.t == 'Plain' and #(it.content) > 0) then
    return false
  end
  local sym = utils.stringify(it.content[1])
  return (sym == t_done or sym == t_todo)
end

function fix_taskitem(item)
  local sym = utils.stringify(item.content[1])
  item.content[1] = pandoc.RawInline("ms", '\\f[FSerR]' .. sym .. '\\f[]')
  return item
end

function is_in(ls, k)
  if ls == nil then
    return false
  end
  for _, it in pairs(ls) do
    if k == it then
      return true
    end
  end
  return false
end

local vars = PANDOC_WRITER_OPTIONS.variables or {}

return {
  {
    BulletList = function(bl)
      -- Fixes taskitem symbols (by rendering them in the FreeRoman font)
      if FORMAT == 'ms' then
        if vars['no-tasklist-filter'] then
          -- We don't need to run this filter since the tasklist symbols
          -- are handled by .char definitions in the template instead
          return
        end
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
    Table = function(t)
      -- Simplistic changes to table appearance:
      -- 1) Double horizontal line at top, single horizontal line at bottom.
      -- 2) Caption is moved to bottom of table and rendered in smaller font.
      -- Limitations: no table numbering; multiblock captions will be ugly.
      if FORMAT == 'ms' then
        local colnum = #(t.colspecs)
        local doc = pandoc.Pandoc({t})
        local s = pandoc.write(doc, 'ms')
        local i, j = s:find('%.PP\n.*%.na\n')
        local caption_s = ''
        if i ~= nil then
          caption_s = s:sub(i, j-4)
          s = s:sub(0, i-1) .. s:sub(j-3)
          caption_s = caption_s:gsub('%.PP\n', '', 1)
        end
        local cap = "_\n"
        if #caption_s then
          cap = cap .. ".T&\n" .. 'lp-1v+3' .. string.rep(' s', colnum-1) .. ".\n"
          cap = cap .. "T{\n" .. caption_s .. "\nT}\n"
        end
        cap = cap .. ".TE\n"
        s = s:gsub("%.TE\n", cap, 1)
        -- The first line ending with a dot is the colspec at the top
        s = s:gsub("%.\n", ".\n=\n", 1)
        s = s:gsub("\n\n+", "\n") -- we almost certainly do not want empty lines
        return pandoc.RawBlock('ms', s)
      end
    end,
    Div = function(div)
      -- Handle fenced div classes and attributes in a configurable
      -- manner through the template variables 'ms-div-classes' and
      -- 'ms-div-attr'.
      -- The action for each key (classname or attribute value) consists
      -- of a two-element list. The first element is prepended, the last
      -- postpended as a RawBLock.
      if FORMAT == 'ms' then
        local id, classes, attr = div.identifier, div.classes, div.attributes
        if id == nil then id = '' end
        id = '#'..id
        if attr == nil then attr = {} end
        local known_cls = vars['ms-div-classes'] or {}
        local known_attr = vars['ms-div-attr'] or {}
        if next(known_cls) == nil and next(known_attr) == nil then
          return
        end
        local ret = {div}
        for atyp, actions in pairs(known_attr) do
          if attr[atyp] and actions[attr[atyp]] then
            local action = actions[attr[atyp]]
            table.insert(ret, 1, pandoc.RawBlock('ms', utils.stringify(action[1])))
            table.insert(ret, pandoc.RawBlock('ms', utils.stringify(action[2])))
          end
        end
        for k, action in pairs(known_cls) do
          if k == id or is_in(classes, k) then
            table.insert(ret, 1, pandoc.RawBlock('ms', utils.stringify(action[1])))
            table.insert(ret, pandoc.RawBlock('ms', utils.stringify(action[2])))
          end
        end
        return pandoc.Blocks(ret)
      end
    end,
    Para = function(p)
      -- Handle (La)TeX `\noindent` at the start of a paragraph
      local c = p.content
      if #c < 2 then
        return
      end
      if c[1].t == 'RawInline' and c[1].format:match('tex$') and c[1].text:match('\\noindent') then
        p.content:remove(1)
        -- Remove initial whitespace from the remainder
        if c[1].t == 'Space' or c[1].t == 'SoftBreak' then
          p.content:remove(1)
        end
        return pandoc.Blocks({
            pandoc.RawBlock('ms', '.nr PI 0m'),
            p,
            pandoc.RawBlock('ms', '.nr PI \\n[PIORIG]')})
      end
    end,
    Header = function(h)
      -- Changes font in headlines based on template variables.
      -- TODO: walk the header object so as to fix italics in a better way
      if FORMAT == 'ms' then
        -- We need to know this so we can switch back to it
        local docfam = utils.stringify(vars['fontfamily'] or '')
        local hfam = utils.stringify(vars['heading-fontfam'] or '')
        local lvl = tonumber(utils.stringify(vars['heading-fontfam-max-level'] or '4'))
        if #docfam > 0 and #hfam > 0 and h.level <= lvl then
          -- Emph in headline switches to \f[B] at the end, which is correct.
          -- However, this font change makes it into the table of contents.
          -- This addition makes sure that this at least only affects the rest
          -- of the headline, not the page number.
          table.insert(h.content, pandoc.RawInline("ms", "\\f[R]"))
          return pandoc.Blocks({
             pandoc.RawBlock('ms', '.ds FAM ' .. hfam),
             pandoc.Header(h.level, h.content, h.attr),
             pandoc.RawBlock('ms', '.ds FAM ' .. docfam)
          })
        end
      end
    end,
  },
}
