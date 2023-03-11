#!/bin/sh

set -e

if [ -d doc-html ]; then
    rm -rf doc-html
fi
mkdir doc-html

docs=$(cmark < $(lua-language-server --doc=. | awk -F ] '/Markdown/ { print $1 }' | awk '{ print substr($2, 2, length($2)) }'))
cat docs/index.html \
    | awk -v docs="$docs" '
        { flag = 1 }
        /{{docs}}/ { flag = 0; print docs }
        flag { print }
    ' > doc-html/index.html
cp docs/style.css doc-html/style.css
