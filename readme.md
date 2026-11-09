# F-Klubbens sangbog skreven i Typst

A continuation of the old [LaTeX sangbog](https://github.com/f-klubben/originalsangbog)

## Req.

- typst 0.14.2
- ImageMagick
- Typst
- pyhton 3
- curl + unzip (for font downloading)

## Building from source

Here, for Debian- and Arch-based systems

1. Fetch source code
```bash
git clone https://github.com/f-klubben/ftsangbog.git
```
2. Install prerequisites
```bash
#Debian
sudo apt install typst imagemagick curl unzip python3

#Arch
sudo pacman -S typst imagemagick curl unzip pyhton
``` 
4. Build the sangbog make `kontinuertpdf` for non-booklet (continuous) format, `make bookletpdf` for booklet format. (Fonts downlaod automatically).

### Oddities

It might be that you have not listed A4 paper in you paper sizes (known issue on wsl). 
For this do the followng: `echo "a4" | sudo tee /etc/papersize`.
(Here you need to install `libpaper1` (Debian) or `libpaper`(Arch) if it is not on your system).

### Fonts

Fonts are **not** included in the repo. They are downloaded automatically from their
official open-source releases the first time you run any compile target.

The following fonts are used:
- [Source Serif 4](https://github.com/adobe-fonts/source-serif) (Adobe)
- [Source Sans 3](https://github.com/adobe-fonts/source-sans) (Adobe)
- [Courier Prime](https://github.com/quoteunquoteapps/CourierPrime)  (quoteunquoteapps)

They are downloaded into `fonts/` (which is git-ignored) and cached via a
`fonts/.downloaded` sentinel file — so they are only fetched once.

## Building using nix (NOT PRESENT, idk how to do nix)

For nix based systems with flakes enabled:

- Fetch the source code
```bash
git clone https://github.com/f-klubben/ftsangbog.git
```
- Enter environment
```bash
nix develop
```
- Build pdf
```bash
make bookletpdf
```
Or build and run the latest version locally: nix run github:INSERTLINKHERE

## Make Usage

### Basic Conversion

```bash
make png    # Convert EPS files to PNG (default, 300 DPI)
make svg    # Convert EPS files to SVG
make pdf    # Convert EPS files to PDF
```

### Typst Compilation

```bash
make kontinuertpdf    # Download fonts + convert to PNG + compile main.typ
make bookletpdf       # Download fonts + convert to PNG + compile + booklet processing
make watch            # Download fonts + convert to PNG + start typst watch mode
# If in watch-mode, it is reccomnded to disable any autosave, and save amnually, ebcause of problems with autofocus when recompiling
```

### Cleanup

```bash
make clean            # Remove all converted files and output
make clean-png        # Remove PNG files only
make clean-svg        # Remove SVG files only
make clean-pdf        # Remove PDF files only
```

### Fonts

```bash
make clean-fonts
make fonts   # or just run any compile target
```

## Adding Songs

Songs are stored in `/sange` so the process of adding a new song
1. `touch ./sange/[songname].typ`
2. Edit `./sange[songname].typ`
3. Add the following in `main.typ`
```typst
#pagebreak() // pagebreak may not be needed, depending on spacing of songs!
#include "sange/[songname].typ"
```

## Ownership change

This repo was originally owned by ever handsome [Naitsa (also known as Sebastian Lorenzen, a F-ordmand)](https://github.com/Naitsabot), but had its ownership transferred to F-Klubben as that was the aspiration for the repo.
