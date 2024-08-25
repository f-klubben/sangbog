FILE=main.tex
OUTPUT_DIR=output

all: pdf

dvi:
	@echo "Compiling .tex to .dvi"
	mkdir -p $(OUTPUT_DIR)
	latex -output-directory=$(OUTPUT_DIR) $(FILE)
	makeindex $(OUTPUT_DIR)/main
	latex -output-directory=$(OUTPUT_DIR) $(FILE)

ps: dvi
	@echo "Converting .dvi to .ps"
	dvips $(OUTPUT_DIR)/main.dvi -o $(OUTPUT_DIR)/main.ps

pdf: dvi
	@echo "Compiling .dvi to .pdf with A4 paper size"
	mkdir -p $(OUTPUT_DIR)
	dvipdfmx -p a4 -o $(OUTPUT_DIR)/main.pdf $(OUTPUT_DIR)/main.dvi
	@echo "PDF should be generated in the $(OUTPUT_DIR) directory: $(OUTPUT_DIR)/main.pdf"

booklet: ps
	@echo "Creating booklet"
	./ps2book.sh $(OUTPUT_DIR)/main.ps
	ps2pdf $(OUTPUT_DIR)/main_book.ps $(OUTPUT_DIR)/main_book.pdf
	rm $(OUTPUT_DIR)/main.ps $(OUTPUT_DIR)/main_book.ps $(OUTPUT_DIR)/main.dvi

clean:
	rm -rf $(OUTPUT_DIR) *.aux *.log *.idx *.ilg *.ind *.toc *.out *.dvi *.ps *.pdf