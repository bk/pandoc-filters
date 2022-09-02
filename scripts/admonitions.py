#!/usr/bin/env python3

import re

def admonition2pandoc(doc):
    """
    Transform Python-Markdown admonitions to Pandoc fenced divs.
    An admonition looks like this:

    !!! note "My title"
        Some text: This is the first pargraph

        Second paragraph.

    Resulting in:

    <div class="admonition note">
    <p class="admonition-title">My title</p>
    <p>Some text: This is the first paragraph.</p>
    <p>Second paragraph.</p>
    </div>

    A missing title results in the admonition type being used as title (capitalized).
    An empty title ('"") results in no title being used.

    Recommended admonition types (taken from rst): attention, caution, danger,
    error, hint, important, note, tip, warning.
    """
    if not re.search(r'^!!! ', doc, flags=re.M):
        return doc
    lines = re.split(r'\r?\n', doc)
    in_note = False
    new = []
    for line in lines:
        if in_note and (line == '' or line.startswith('    ')):
            new.append(line[4:])
        elif in_note:
            new.append(':::')
            new.append('')
            in_note = False
        elif line.startswith('!!! '):
            in_note = True
            hdr = line[4:].strip()
            if ' ' in hdr:
                typ, title = re.split(r' +', hdr, 2)
                if title.startswith(('"', "'")) and title.endswith(('"', "'")):
                    title = title[1:-1]
            else:
                typ = title = hdr
                title = title[0].upper() + title[1:]
            new.append('::: {.admonition .%s}' % typ)
            if title:
                new.append('<p class="admonition-title">%s</p>' % title)
                new.append('')
        else:
            new.append(line)
    if in_note:
        new.append(':::')
    return "\n".join(new)


if __name__ == '__main__':
    import sys

    doc = ''
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            doc = f.read()
    else:
        doc = sys.stdin.read()

    print(admonition2pandoc(doc))
