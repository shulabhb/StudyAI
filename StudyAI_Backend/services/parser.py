# services/parser.py
"""
OCR helper – extracts text from an image (PNG, JPG, etc.).
"""
import io
from typing import Union

from PIL import Image
import pytesseract


def extract_text_from_image(image_bytes: Union[bytes, bytearray]) -> str:
    """Return UTF-8 text extracted via Tesseract."""
    with Image.open(io.BytesIO(image_bytes)) as img:
        img = img.convert("RGB")  # ensure 3-channel for better OCR
        return pytesseract.image_to_string(img)
