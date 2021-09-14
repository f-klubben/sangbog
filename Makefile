FILE=main.tex
DVIFILE=main.dvi
PSFILE=main.ps
PSBOOKFILE=main_book.ps

all: dvi

dvi:
	latex $(FILE)

ps: dvi
	dvips $(DVIFILE)

pdf: dvi
	makeindex main
	dvipdf -ta4 $(DVIFILE)

booklet: ps
	./ps2book.sh $(PSFILE)
	ps2pdf $(PSBOOKFILE)
	rm $(PSFILE) $(PSBOOKFILE) $(DVIFILE)

