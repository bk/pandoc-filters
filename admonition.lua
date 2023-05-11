-- Simplistic filter for admonitions of the type supported by Python-Markdown.
-- They look like this:
-- 
-- !!! note
--     The paragraph starts here
--
-- !!! danger "With a title!"
--     Title is allowed
--
-- The Python-Markdown parser allows further indented paragraphs but this
-- filter does not support that; they will appear as code blocks instead.

function Para (para)
    if para.content[1].text == "!!!" then
        classes = {'admonition'}
        title = ''
        blocks = {}
        inlines = {}
        saw_break = false
        saw_nonspace = false
        for i, elem in pairs(para.content) do
            if i > 1 and not saw_break then
                if elem.tag == 'SoftBreak' then
                    saw_break = true
                    titlep = pandoc.RawBlock('html','<p class="admonition-title">'..title..'</p>')
                    table.insert(blocks, titlep)
                elseif elem.tag == 'Quoted' then
                    title = pandoc.utils.stringify(elem.content)
                elseif not saw_break and saw_nonspace then
                    title = title .. pandoc.utils.stringify(elem)
                elseif elem.tag == 'Str' then
                    saw_nonspace = true
                    tc = pandoc.utils.stringify(elem)
                    title = title .. tc:gsub("^%l", string.upper)
                    if #classes == 1 then
                        table.insert(classes, tc)
                    end
                end
            elseif saw_break then
                table.insert(inlines, elem)
            end
        end
        table.insert(blocks, pandoc.Para(inlines))
        return pandoc.Div(blocks, pandoc.Attr('', classes))
    end
end
