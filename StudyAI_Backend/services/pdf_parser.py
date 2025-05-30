from pdfminer.high_level import extract_text
from tempfile import NamedTemporaryFile

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    with NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
        tmp_file.write(pdf_bytes)
        tmp_path = tmp_file.name

    try:
        return extract_text(tmp_path)
    except Exception as e:
        print(f"❌ PDF parsing failed: {e}")
        return ""
