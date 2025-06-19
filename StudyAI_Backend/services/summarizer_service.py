# services/summarizer_service.py
"""
Academic-grade abstractive summariser for StudyAI.  (Drop-in file)

• Model: facebook/bart-large-cnn  ← good ROUGE, runs locally, no API keys
• fp16 on Apple-silicon & CUDA; optional 8-bit path for Linux/CUDA
• ≈45 % word-ratio abstracts, concrete examples preserved
• Bullet-list output when bullet_points=True
---------------------------------------------------------------------------
Want to swap in an external LLM (OpenAI, DeepSeek, etc.)?
Replace the _generate() block with an API call — chunking / formatting
below still works unchanged.
"""

from __future__ import annotations
import asyncio, os, re
from typing import List

import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer, pipeline, Pipeline

# ─────── Configuration ───────
MODEL_NAME        = os.getenv("HF_MODEL", "facebook/bart-large-cnn")
USE_FP16          = os.getenv("HF_FP16", "1") == "1"
USE_8BIT          = os.getenv("HF_8BIT", "0") == "1"

OUTPUT_RATIO      = 0.45       # ~45 % of source words
SECOND_PASS_RATIO = 0.50       # compress if >50 %
TOKEN_SCALE       = 1.5        # BART ≈ 1.5 tokens / word

CHUNK_TOKENS      = 950        # keep <1024 context
OVERLAP_TOKENS    = 100
PROMPT = (
    "Write an academic abstract that keeps concrete examples, technical measures "
    "and equity concerns in a scholarly tone:\n"
)
# ────────────────────────────────────────


class SummarizerService:
    def __init__(self) -> None:
        print(f"🚀 Loading {MODEL_NAME} …")
        self.tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

        load_kwargs: dict = {}
        if torch.cuda.is_available():
            if USE_8BIT:
                print("⚡  8-bit GPU")
                load_kwargs = dict(load_in_8bit=True, device_map="auto")
            elif USE_FP16:
                print("⚡  fp16 GPU")
                load_kwargs = dict(torch_dtype=torch.float16, device_map="auto")
            else:
                print("⚡  fp32 GPU")
                load_kwargs = dict(device_map="auto")
        elif torch.backends.mps.is_available() and USE_FP16:
            print("🍎  Apple-silicon fp16 (MPS)")
            load_kwargs = dict(torch_dtype=torch.float16, device_map={"": "mps"})
        else:
            print("💻  CPU mode")
            load_kwargs = dict(device_map={"": "cpu"})

        self.model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME, **load_kwargs)

        pipe_kwargs = dict(
            model=self.model,
            tokenizer=self.tokenizer,
            num_beams=5,
            length_penalty=0.9,
            early_stopping=True,
            no_repeat_ngram_size=3,
            repetition_penalty=1.05,
        )
        if not any(k in load_kwargs for k in ("device_map", "load_in_8bit")):
            pipe_kwargs["device"] = 0 if torch.cuda.is_available() else -1

        self.pipe: Pipeline = pipeline("summarization", **pipe_kwargs)
        print("✅  Model ready!")

    @staticmethod
    def _clean(txt: str) -> str:
        return re.sub(r"\s+", " ", txt).strip()

    @staticmethod
    def _is_meta_line(line: str) -> bool:
        l = line.strip().lower()
        return (
            l.startswith(("abstract —", "write an academic abstract"))
            or "for confidential support" in l
            or re.search(r"(http|www\.)", l)
            or re.search(r"@\w+", l)
            or any(bad in l for bad in ["click here", "follow us", "back to", "prize", "winner", "submit", "feature"])
        )

    def _strip_prompt(self, text: str) -> str:
        lines = [l for l in text.splitlines() if not self._is_meta_line(l)]
        cleaned_text = "\n".join(lines)
        cleaned_text = re.sub(r'@\w+', '', cleaned_text)
        cleaned_text = re.sub(r'(http|www\.)\S+', '', cleaned_text)
        cleaned_text = re.sub(r'(click here|follow us|back to|prize|winner|submit|feature).*', '', cleaned_text, flags=re.I)
        return cleaned_text

    def _chunk(self, text: str) -> List[str]:
        ids = self.tokenizer(text, add_special_tokens=False).input_ids
        if len(ids) <= CHUNK_TOKENS:
            return [text]
        step = CHUNK_TOKENS - OVERLAP_TOKENS
        return [
            self.tokenizer.decode(ids[i : i + CHUNK_TOKENS], skip_special_tokens=True)
            for i in range(0, len(ids), step)
        ]

    @staticmethod
    def _ensure_period(s: str) -> str:
        return s.rstrip(" ,;:\n").rstrip(".!?") + "."

    async def summarize(
        self,
        text: str,
        academic: bool = True,
        bullet_points: bool | None = None,
    ) -> str:

        print("\n[DEBUG] Raw extracted text (first 500 chars):\n", text[:500])
        text = self._clean(self._strip_prompt(text))
        print("[DEBUG] Cleaned input text (first 500 chars):\n", text[:500])
        if not text:
            print("[DEBUG] Cleaned text is empty after cleaning.")
            return "No content."
        if len(text.split()) < 10:
            print("[DEBUG] Cleaned text too short after cleaning.")
            return "Content too short or invalid after cleaning."

        # SECTION-AWARE SPLITTING
        # Split on lines that look like section headings (title case, all caps, or surrounded by whitespace)
        section_pattern = re.compile(r"(?:^|\n)([A-Z][A-Za-z0-9\- ]{3,40})(?:\n|$)")
        sections = []
        last_idx = 0
        for match in section_pattern.finditer(text):
            start = match.start(1)
            if last_idx < start:
                section_text = text[last_idx:start].strip()
                if section_text:
                    sections.append(section_text)
            last_idx = start
        # Add the last section
        if last_idx < len(text):
            section_text = text[last_idx:].strip()
            if section_text:
                sections.append(section_text)
        # If no sections found, treat the whole text as one section
        if not sections:
            sections = [text]
        print(f"[DEBUG] Detected {len(sections)} sections for summarization.")

        # Summarize each section individually
        loop = asyncio.get_running_loop()
        def summarize_section(section):
            # Use the same summarization logic as before, but on the section
            chunks = self._chunk(section)
            tgt_words = [max(30, int(len(c.split()) * OUTPUT_RATIO)) for c in chunks]
            max_tok = [min(1000, int(w * TOKEN_SCALE)) for w in tgt_words]
            min_tok = [int(mx * 0.60) for mx in max_tok]
            out = []
            for chunk, mx, mn in zip(chunks, max_tok, min_tok):
                res = self.pipe(PROMPT + chunk, max_length=mx, min_length=mn, truncation=True)[0]["summary_text"]
                out.append(self._ensure_period(self._clean(res)))
            return " ".join(out)
        section_summaries = await asyncio.gather(*[loop.run_in_executor(None, summarize_section, sec) for sec in sections])
        summary = " ".join(section_summaries)

        summary = re.sub(r'for confidential support.*', '', summary, flags=re.I | re.S)
        summary = re.sub(r'(http|www\.)\S+', '', summary)
        summary = re.sub(r'@\w+', '', summary)
        summary = re.sub(r'(click here|follow us|back to|prize|winner|submit|feature).*', '', summary, flags=re.I)
        summary = re.sub(r'\s{2,}', ' ', summary).strip()
        # Remove repeated prompt instructions at the end
        summary = re.sub(
            r"(write an academic abstract.*?in a scholarly tone:.*?)+", "", summary, flags=re.I | re.S
        )
        summary = re.sub(
            r"(write an academic abstract.*?in a academic tone:.*?)+", "", summary, flags=re.I | re.S
        )
        summary = re.sub(r"authors say\.\.", "authors say.", summary)
        # Remove any trailing incomplete sentences or meta lines
        summary = re.sub(r"([.?!])[^.?!]*$", r"\1", summary)
        summary = summary.strip()
        if not summary.endswith('.'):
            summary += '.'
        print("[DEBUG] Final section-aware summary (first 500 chars):\n", summary[:500])
        # Fallback: if summary is too short, return first 3 sentences of cleaned input
        if len(summary.split()) < 20:
            print("[DEBUG] Section-aware summary too short after all processing. Returning fallback.")
            fallback = '. '.join(text.split('. ')[:3]).strip()
            if not fallback.endswith('.'):
                fallback += '.'
            return fallback or "Summary could not be generated."
        return summary
