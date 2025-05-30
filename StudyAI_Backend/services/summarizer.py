# summarizer.py
import re
from transformers import pipeline

# Load summarizer model
primary_model = pipeline("summarization", model="facebook/bart-large-cnn")

# Summary configurations for different types
summary_configs = {
    "short":    {"max_length": 80,  "min_length": 30},
    "medium":   {"max_length": 150, "min_length": 60},
    "detailed": {"max_length": 300, "min_length": 120},
    "academic": {"max_length": 400, "min_length": 200},
}

def clean_text(text: str) -> str:
    text = text.replace('\n', ' ')
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def chunk_text(text: str, max_tokens: int = 900) -> list:
    sentences = text.split('. ')
    chunks = []
    current_chunk = ""
    for sentence in sentences:
        if len((current_chunk + sentence).split()) <= max_tokens:
            current_chunk += sentence + ". "
        else:
            chunks.append(current_chunk.strip())
            current_chunk = sentence + ". "
    if current_chunk:
        chunks.append(current_chunk.strip())
    return chunks

def summarize_chunk(chunk: str, model, summary_type: str) -> str:
    config = summary_configs.get(summary_type, summary_configs["medium"])
    prompt = f"Summarize this text in a formal academic tone with clear points, without fabricating sources:\n{chunk}" if summary_type == "academic" else chunk
    try:
        result = model(
            prompt,
            max_length=config["max_length"],
            min_length=config["min_length"],
            do_sample=False
        )
        return result[0]["summary_text"]
    except Exception as e:
        print(f"❌ Failed to summarize chunk: {e}")
        return ""

def summarize_final(text: str, model, summary_type: str) -> str:
    config = summary_configs.get(summary_type, summary_configs["medium"])
    prompt = f"Summarize this text as structured academic notes:\n{text}" if summary_type == "academic" else text
    try:
        return model(prompt, max_length=config["max_length"], min_length=config["min_length"], do_sample=False)[0]["summary_text"]
    except Exception as e:
        print(f"❌ Final summarization failed: {e}")
        return ""

def summarize_text(text: str, summary_type: str = "medium") -> str:
    text = clean_text(text)
    if not text:
        return "No content to summarize."

    # Set lengths and prompt based on type
    summary_type = summary_type.lower()
    if summary_type == "short":
        max_len, min_len = 60, 20
        final_prompt = "Give a very short summary of this text:"
    elif summary_type == "medium":
        max_len, min_len = 120, 40
        final_prompt = "Summarize this text clearly:"
    elif summary_type == "detailed":
        max_len, min_len = 240, 100
        final_prompt = "Write a detailed summary of this text with key ideas explained:"
    elif summary_type == "academic":
        max_len, min_len = 300, 120
        final_prompt = "Summarize this text in a formal academic tone with clear points, no fake citations:"
    else:
        max_len, min_len = 120, 40
        final_prompt = "Summarize this text clearly:"

    # Split into chunks if needed
    chunks = chunk_text(text)
    print(f"🔍 Total chunks created: {len(chunks)}")

    chunk_summaries = []
    for i, chunk in enumerate(chunks):
        print(f"📚 Summarizing chunk {i+1}/{len(chunks)}")
        try:
            input_length = len(chunk.split())
            dynamic_max = max(60, min(max_len, int(input_length * 0.7)))
            dynamic_min = max(30, min(min_len, int(input_length * 0.4)))
            summary = primary_model(f"{final_prompt}\n{chunk}", max_length=dynamic_max, min_length=dynamic_min, do_sample=False)[0]["summary_text"]
            chunk_summaries.append(summary)
        except Exception as e:
            print(f"❌ Chunk summarization failed: {e}")
            continue

    if not chunk_summaries:
        return "Unable to summarize content."

    combined = "\n".join(chunk_summaries)

    # Final layer of summarization
    try:
        final_summary = primary_model(f"{final_prompt}\n{combined}", max_length=max_len, min_length=min_len, do_sample=False)[0]["summary_text"]
    except Exception as e:
        print(f"❌ Final summarization failed: {e}")
        return combined

    if final_summary.lower().strip().startswith(text[:50].lower().strip()) or len(final_summary.split()) < 30:
        print("⚠️ Final summary weak, using combined chunk summary.")
        return combined

    return final_summary

