OUTPUT_DIR = output
FILE_KONTINUERT = kontinuert/main.tex
FILE_BOOKLET = booklet/main.tex
DVI_FILE_KONTINUERT = $(OUTPUT_DIR)/kontinuert/main.dvi
PDF_FILE_KONTINUERT = $(OUTPUT_DIR)/kontinuert/kontinuert.pdf

.PHONY: all dvi kontinuertpdf bookletpdf clean

all: kontinuertpdf bookletpdf

dvi:
	mkdir -p $(OUTPUT_DIR)/kontinuert
	latex -output-directory=$(OUTPUT_DIR)/kontinuert $(FILE_KONTINUERT)
	makeindex $(OUTPUT_DIR)/kontinuert/main.idx
	latex -output-directory=$(OUTPUT_DIR)/kontinuert $(FILE_KONTINUERT)

# WARNING: IF YOU CHANGE THE FODLER STRUCTURE HERE; YOU NEED TO CHANGE THE FODLER STRUCUTRE IN THE CI/CD

kontinuertpdf:
	@echo "Compiling .dvi to .pdf with A4 paper size"
	mkdir -p $(OUTPUT_DIR)/kontinuert
	$(MAKE) dvi
	dvipdfmx -p a4 -o $(PDF_FILE_KONTINUERT) $(DVI_FILE_KONTINUERT)
	@echo "PDF generated at $(PDF_FILE_KONTINUERT)"

bookletpdf:
	if ! test -f $(PDF_FILE_KONTINUERT); then $(MAKE) kontinuertpdf; fi
	@echo "Compiling .dvi to .pdf with A4 paper size"
	mkdir -p $(OUTPUT_DIR)/booklet
	pdflatex -output-directory=$(OUTPUT_DIR)/booklet -jobname=booklet $(FILE_BOOKLET)
	@echo "PDF generated at $(OUTPUT_DIR)/booklet/booklet.pdf"

clean:
	rm -rf $(OUTPUT_DIR) *.aux *.log *.idx *.ilg *.ind *.toc *.out *.dvi *.ps *.pdf