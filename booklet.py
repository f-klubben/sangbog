from PyPDF2 import PdfReader, PdfWriter, PageObject, Transformation

def create_booklet(input_pdf_path, output_pdf_path):
    reader = PdfReader(input_pdf_path)
    writer = PdfWriter()
    num_pages = len(reader.pages)

    # Calculate how many blank pages to add
    remainder = num_pages % 4
    if remainder != 0:
        blank_pages_needed = 4 - remainder
        for _ in range(blank_pages_needed):
            # Add a blank A4 page (same size as the original)
            blank_page = PageObject.create_blank_page(
                width=reader.pages[0].mediabox.width,
                height=reader.pages[0].mediabox.height
            )
            writer.add_page(blank_page)

    # Recalculate the total number of pages after adding blanks
    total_pages = num_pages + (blank_pages_needed if remainder != 0 else 0)

    # Calculate the new page order for booklet
    page_order = []
    for i in range(0, total_pages, 4):
        page_order.extend([total_pages - i - 1, i, i + 1, total_pages - i - 2])

    # Add pages to the writer in the new order
    for page_num in page_order:
        if page_num < num_pages:
            writer.add_page(reader.pages[page_num])

    # Write the output PDF
    with open(output_pdf_path, "wb") as output_pdf:
        writer.write(output_pdf)


def two_pages_per_sheet(input_pdf_path, output_pdf_path):
    reader = PdfReader(input_pdf_path)
    writer = PdfWriter()

    # Get the width and height of the original pages (A4 portrait)
    original_width = reader.pages[0].mediabox.width
    original_height = reader.pages[0].mediabox.height

    # Calculate the new width for the landscape page (double the original width)
    new_width = original_width * 2
    new_height = original_height

    # Iterate through the pages in steps of 2
    for i in range(0, len(reader.pages), 2):
        # Create a new blank landscape page
        new_page = PageObject.create_blank_page(width=new_width, height=new_height)

        # Add the first page (left side)
        if i < len(reader.pages):
            page1 = reader.pages[i]
            new_page.merge_page(page1)

        # Add the second page (right side)
        if i + 1 < len(reader.pages):
            page2 = reader.pages[i + 1]
            # Translate the second page to the right side
            page2.add_transformation(Transformation().translate(tx=original_width, ty=0))
            new_page.merge_page(page2)

        # Add the new page to the writer
        writer.add_page(new_page)

    # Write the output PDF
    with open(output_pdf_path, "wb") as output_pdf:
        writer.write(output_pdf)

# Example usage
create_booklet("output/kontinuert/kontinuert.pdf", "booklet.pdf")