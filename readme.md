# pandoc-filters

This is a personal collection of (Lua) filters for pandoc.

## Filters for roff ms output

These filters (especially `fixes-ms.lua`) are intended for use with the `bk.ms` template and the `ms.yaml` defaults file.

### fixes-ms.lua

- Fixes tasklist items by switching to the `FSerR` font for taskitem symbols. (Also replaces the crossed box symbol with a checked box symbol, for purely aesthetic reasons).
- Enables "true" underline. The default underline rendering in Pandoc roff ms output is italic; the filter uses the `.UL` macro instead.
- Tables are rendered with a double horizontal line at the top of the table, as well as a single horizontal line at the bottom of the header and at the end of the table. The caption is moved below the terminating line and shown in a smaller font. It is part of the table, and thus will be constrained to its width.
- Fenced divs are rendered differently based on their classes or attributes as specified in the writer variables `ms-div-classes` and `ms-div-attr`.
- Headers with a distinct font family based on the writer variables `heading-fontfam` and `heading-fontfam-max-level`.

### image-ms.lua

Make images work in PDF output based on roff ms by using the `.PDFPIC` macro.  Limitations:

-  Works only with local images.
-  Primarily intended for 'figures', i.e. images with a caption, appearing by themselves in a paragraph.
-  Other images will appear also (without caption) but are not really inline; they will break the text and appear on a line by themselves.
-  Image directories must be writable or already contain PDF images with the correct filenames.
-  Image PDF conversion requires ImageMagick or equivalent (the "convert" command).
-  Automatic size determination requires pdfinfo (part of Poppler).
