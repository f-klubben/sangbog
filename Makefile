OUTPUT_DIR = output
FILE_KONTINUERT = kontinuert/main.tex
FILE_BOOKLET = booklet/main.tex
DVI_FILE_KONTINUERT = $(OUTPUT_DIR)/kontinuert/main.dvi
DVI_FILE_BOOKLET = $(OUTPUT_DIR)/booklet/main.dvi

all: dvi_kontinuert dvi_booklet

dvi_kontinuert: 
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/kontinuert
	latex -output-directory=$(OUTPUT_DIR)/kontinuert $(FILE_KONTINUERT)
	makeindex $(OUTPUT_DIR)/kontinuert
	latex -output-directory=$(OUTPUT_DIR)/kontinuert $(FILE_KONTINUERT)

dvi_booklet:
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/booklet
	latex -output-directory=$(OUTPUT_DIR)/booklet $(FILE_BOOKLET)
	makeindex $(OUTPUT_DIR)/booklet
	latex -output-directory=$(OUTPUT_DIR)/booklet $(FILE_BOOKLET)

kontinuert: dvi_kontinuert
	@echo "Compiling .dvi to .pdf with A4 paper size"
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/booklet
	dvipdfmx -p a4 -o $(OUTPUT_DIR)/kontinuert.pdf $(DVI_FILE_KONTINUERT)
	@echo "PDF should be generated in the $(OUTPUT_DIR) directory: $(OUTPUT_DIR)/kontinuert.pdf"

booklet: dvi_booklet
	@echo "Compiling .dvi to .pdf with A5 paper size"
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/booklet
	dvipdfmx -p a5 -o $(OUTPUT_DIR)/booklet.pdf $(DVI_FILE_BOOKLET)
	@echo "PDF should be generated in the $(OUTPUT_DIR) directory: $(OUTPUT_DIR)/booklet.pdf"

clean:
	rm -rf $(OUTPUT_DIR) *.aux *.log *.idx *.ilg *.ind *.toc *.out *.dvi *.ps *.pdf
