#!/bin/bash

#ln -s /workspaces/flib /usr/local/share/lua/5.2/__flib__

wget -q --no-check-certificate -O ../.luacheckrc https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/master/.luacheckrc

luacheck .

busted .

echo 'Auto Generating with ldoc'
rm -rf 'flib-docs'
mkdir -p 'flib-docs'
cp docs/css/spectre.min.css 'flib-docs/spectre.min.css'
cp docs/css/spectre-icons.min.css 'flib-docs/spectre-icons.min.css'
ldoc -ic docs/ldoc-config.ld ./
