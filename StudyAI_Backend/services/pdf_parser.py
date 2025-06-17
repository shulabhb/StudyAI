# services/pdf_parser.py
"""
Lightweight PDF → text extraction using pdfminer.six.
"""
from tempfile import NamedTemporaryFile

from pdfminer.high_level import extract_text


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Write bytes to a temp file (required by pdfminer) and extract text."""
    with NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
        tmp_file.write(pdf_bytes)
        tmp_path = tmp_file.name

    try:
        return extract_text(tmp_path)
    except Exception as exc:
        print(f"❌ PDF parsing failed: {exc}")
        return ""
