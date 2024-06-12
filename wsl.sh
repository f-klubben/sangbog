#!/usr/bin/env bash

# if nix on wsl, undo some symlinking
nix build $@

cp -L result main.pdf

echo "The PDF has been built using nix on wsl, to be accessible from windows the pdf has been moved here as well as `main.pdf`"
