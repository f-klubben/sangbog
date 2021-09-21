Sangbogen
========

This is the current sangbog in the F-Klub

Latex Environment
-------------
For apt systems:
1. In a shell
  - `git clone https://github.com/f-klubben/stregsystemet.git`
2. Install needed packages:
  - `sudo apt install texlive-latex-extra psutils texlive-lang-european`
3. Build the sangbog
  - `make booklet`
4. Add new songs
  - `touch ./sange/xxx.tex`
  - Then add the file to main.tex
