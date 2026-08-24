Sangbogen
========

This is the current songbook in the F-Klub

Download
-------------
The latest songbook can be downloaded in booklet format ready for printing [here](https://github.com/f-klubben/sangbog/releases/latest/download/booklet.pdf) and in a readable continuous format in [here](https://github.com/f-klubben/sangbog/releases/latest/download/booklet.pdf). You can also follow the build instructions below.

Building from source
-------------
For Debian-based systems (in other distributions package names may vary):
1. Fetch the source code
```sh
git clone https://github.com/f-klubben/sangbog.git
```
2. Install prerequisites:
```sh
sudo apt install texlive-latex-extra texlive-lang-european
sudo apt install python3 python3-pypdf # This is a bad way, use an .venv instead
```
```sh
sudo pacman -S texlive-latex texlive-latexextra texlive-langeuropean texlive-fontsrecommended texlive-plaingeneric
sudo pacman -S python python-pypdf # This is a bad way, use an .venv instead
```
3. Build the sangbog
`make kontinuertpdf` for non-booklet (continuous) format, `make bookletpdf` for booklet format (python3 and pypdf packages needed, since the booklet is generated from the continuous PDF via `generate_booklet.py`).

Building using nix
-------------
For nix based systems with flakes enabled:
  1. Fetch the source code
  ```sh 
  git clone https://github.com/f-klubben/sangbog.git
  ```
  2. Enter environment
  ```sh
  nix develop
  ```
  3. Build pdf
  ```sh
  make bookletpdf
  ```
Or build and run the latest version locally: `nix run github:f-klubben/sangbog`

Adding new songs
-------------
Songs are stored in `/sange` so the process of adding a new song is
  1. `touch ./sange/[songname].tex`
  2. Edit `./sange/[songname].tex`
  3. Add the following in `main.tex`
  ```latex
  \newpage
  \input{sange/[songname].tex}
  ```
