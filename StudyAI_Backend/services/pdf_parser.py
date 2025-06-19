# services/pdf_parser.py
"""
Lightweight PDF → text extraction using pdfminer.six.
"""
import os
from tempfile import NamedTemporaryFile

from pdfminer.high_level import extract_text


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Write bytes to a temp file (required by pdfminer) and extract text."""
    if not pdf_bytes:
        print("❌ PDF bytes are empty")
        return ""
    
    print(f"📄 Processing PDF with {len(pdf_bytes)} bytes")
    
    with NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
        tmp_file.write(pdf_bytes)
        tmp_path = tmp_file.name

    try:
        extracted_text = extract_text(tmp_path)
        print(f"✅ Successfully extracted {len(extracted_text)} characters from PDF")
        return extracted_text
    except Exception as exc:
        print(f"❌ PDF parsing failed: {exc}")
        return ""
    finally:
        # Clean up the temporary file
        try:
            os.unlink(tmp_path)
        except OSError:
            pass  # File might already be deleted
