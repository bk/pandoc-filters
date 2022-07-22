local text = require 'text'
local utils = require 'pandoc.utils'
local system = require 'pandoc.system'
local path = require 'pandoc.path'

function endswith(String, End)
  return End == '' or string.sub(String, - string.len(End)) == End
end

function file_exists(name)
  -- file exists if it is readable
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function convert_measurements(size, check_percent)
  -- convert and guess HTML/LaTeX units to [gt]roff units
  if size ~= nil then
    -- print("size before: " .. size)
    size = string.gsub(size, "[;:,]$", "")
    -- Assumes 72 dpi and an approximate text width of 5.9in == 425p
    -- This is not appropriate for height values.
    if check_percent and endswith(size, '%') then
      size = string.gsub(size, "[^%.%d]", "")
      size = tonumber(size) * 0.01 * 425.0
      size = tostring(size) .. 'p'
    end
    size = string.gsub(size, "pt$", "p") -- pt called p
    size = string.gsub(size, "px$", "p") -- assuming 72 dpi, 1px is 1p
    size = string.gsub(size, "em$", "m") -- em called m
    size = string.gsub(size, "ex$", "n") -- ex called n
    if (string.match(size, "^[0-9.]+cm") or
      string.match(size, "^[0-9.]+p") or
      string.match(size, "^[0-9.]+P") or
      string.match(size, "^[0-9.]+in")) then
      -- print("size after: " .. size)
      return size
    end
  end
  return nil
end

return {
  {
    Image = function (im)
      -- cf. https://github.com/jgm/pandoc/issues/4475
      if FORMAT == "ms" then
        -- Assumes centering. Other options: -L, -R
        pat = '.PDFPIC -C'
        local im_src_old = im.src
        local im_src_new = string.gsub(im.src, "%.[^.]+$", ".pdf")
        if not endswith(text.lower(im.src), ".pdf") then
          im.src = path.join({
              system.get_working_directory(),
              im_src_new})
        end
        if not file_exists(im.src) and file_exists(im_src_old) then
          -- if this fails, check policies in /etc/ImageMagick-[67]/policy.xml
          -- whether they forbid conversion of EPS, PDF etc.
          pandoc.pipe("convert", {im_src_old, im.src}, "")
        end
        pat = pat .. string.format(' "%s"', im.src)
        if im.attributes ~= nil then
          local no_explicit_width = true
          if im.attributes.width ~= nil then
            im.attributes.width = convert_measurements(im.attributes.width, true)
            no_explicit_width = false
          end
          if im.attributes.height ~= nil then
            im.attributes.height = convert_measurements(im.attributes.height, false)
          end
          size = pandoc.pipe('pdfinfo', {im.src}, "")
          local w
          local h
          _, _, w, h = string.find(size, "Page size:%s+([%d.]+)%s+x%s+([%d.]+)")
          local height = im.attributes.height or (no_explicit_width and h and (h .. "p")) or nil
          local width = im.attributes.width or w and (w .. "p") or nil
          if width ~= nil then
            pat = pat .. string.format(' %s', width)
            -- height only matters if width was given
            if height ~= nil then
              pat = pat .. string.format(' %s', height)
            end
          end
        end
        cap = utils.stringify(im.caption)
        if cap ~= nil and cap ~= '' then
          pat = pat .. '\n.CD\n\\s-2\\f[I]' .. cap .. '\\f[R]\\s0\n.DE\n'
        end
        return pandoc.RawInline("ms", pat)
      end
    end,
  }
}
