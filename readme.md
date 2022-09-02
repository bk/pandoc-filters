# pandoc-filters

This is a personal collection of (Lua) filters for pandoc.

## Filters for roff ms output

These filters (especially `fixes-ms.lua`) are intended for use with the `bk.ms` template and the `ms.yaml` defaults file.

### fixes-ms.lua

- Fixes tasklist items by switching to the `FSerR` font for taskitem symbols. (Also replaces the crossed box symbol with a checked box symbol, for purely aesthetic reasons).
- Enables "true" underline. The default underline rendering in Pandoc roff ms output is italic; the filter uses the `.UL` macro instead.
- Table appearance is changed slightly. Tables are rendered with a double horizontal line at the top, as well as a single horizontal line below the header and at the end of the table. The caption is moved below the terminating line and shown in a smaller font; it will be constrained to the width of the table.
- Fenced divs are rendered differently based on their classes or attributes as specified in the writer variables `ms-div-classes` and `ms-div-attr`.
- The LaTeX command `\noindent` at the start of a paragraph is handled as expected.
- Headers with a distinct font family based on the writer variables `heading-fontfam` and `heading-fontfam-max-level`.

### image-ms.lua

Make images work in PDF output based on roff ms by using the `.PDFPIC` macro.  Limitations:

-  Works only with local images.
-  Primarily intended for 'figures', i.e. images with a caption, appearing by themselves in a paragraph.
-  Other images will appear also (without caption) but are not really inline; they will break the text and appear on a line by themselves.
-  Image directories must be writable or already contain PDF images with the correct filenames.
-  Image PDF conversion requires ImageMagick or equivalent (the `convert` command).
-  Automatic size determination requires `pdfinfo` (part of Poppler).

## Filters for LaTeX output

### fixes-tex.lua

- Fenced divs to environments by known class, or by `data-latex-environment` attribute.
- H6 support.

## Scripts

### admonitions.py

Transform Python-Markdown admonitions to Pandoc fenced divs. When run as a
script may either take a single filename or read markdown content from stdin.

An [admonition](https://python-markdown.github.io/extensions/admonition/) looks
like this:

```markdown
!!! note "My title"
    Some text: This is the first paragraph

    Second paragraph.
```

Resulting in this HTML output when processed:

```html
<div class="admonition note">
  <p class="admonition-title">My title</p>
  <p>Some text: This is the first paragraph.</p>
  <p>Second paragraph.</p>
</div>
```

A missing title results in the admonition type being used as title (capitalized).
An empty title (`""`) results in no title being used.

Recommended admonition types (the same as for RsT): attention, caution, danger,
error, hint, important, note, tip, warning.
