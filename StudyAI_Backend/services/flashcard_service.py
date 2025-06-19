"""
Flashcard generation service using the existing summarizer model.
Uses the same BART model but with a flashcard-specific prompt.
"""

from __future__ import annotations
import asyncio
import re
from typing import List, Dict, Any

from models.flashcard import Flashcard, FlashcardSet


class FlashcardService:
    def __init__(self, summarizer_service):
        """
        Initialize with the existing summarizer service to reuse the model.
        """
        self.summarizer = summarizer_service
        
    def _clean_text(self, text: str) -> str:
        """Clean and prepare text for flashcard generation."""
        # Remove extra whitespace and normalize
        text = re.sub(r'\s+', ' ', text).strip()
        # Remove any code blocks or technical artifacts
        text = re.sub(r'```.*?```', '', text, flags=re.DOTALL)
        text = re.sub(r'`.*?`', '', text)
        return text
    
    def _parse_flashcards_from_response(self, response: str) -> List[Flashcard]:
        """
        Parse the model response to extract Q&A pairs.
        Handles various formats the model might return.
        """
        flashcards = []
        
        # Clean the response first
        response = re.sub(r'\s+', ' ', response).strip()
        
        # Try different patterns to extract Q&A pairs
        patterns = [
            # Pattern 1: "Q: question A: answer"
            r'Q:\s*(.*?)\s*A:\s*(.*?)(?=Q:|$)',
            # Pattern 2: "Question: question Answer: answer"
            r'Question:\s*(.*?)\s*Answer:\s*(.*?)(?=Question:|$)',
            # Pattern 3: "1. question? answer"
            r'\d+\.\s*(.*?\?)\s*(.*?)(?=\d+\.|$)',
            # Pattern 4: "question? answer"
            r'([^.!?]+\?)\s*(.*?)(?=[^.!?]+\?|$)',
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
            if matches:
                for question, answer in matches:
                    question = question.strip()
                    answer = answer.strip()
                    
                    # Clean up the question and answer
                    question = re.sub(r'^\d+\.\s*', '', question)
                    answer = re.sub(r'^\d+\.\s*', '', answer)
                    
                    # Remove any remaining artifacts
                    question = re.sub(r'\[.*?\]', '', question)
                    answer = re.sub(r'\[.*?\]', '', answer)
                    answer = re.sub(r'\(.*?\)', '', answer)
                    
                    # Ensure question ends with ?
                    if not question.endswith('?'):
                        question += '?'
                    
                    # Only add if both question and answer are substantial
                    if len(question) > 10 and len(answer) > 10:
                        flashcards.append(Flashcard(
                            question=question,
                            answer=answer
                        ))
                
                if flashcards:
                    break
        
        # If no structured format found, try to create flashcards from sentences
        if not flashcards:
            sentences = re.split(r'[.!?]+', response)
            sentences = [s.strip() for s in sentences if len(s.strip()) > 20]
            
            # Create simple flashcards from key sentences
            for i, sentence in enumerate(sentences[:10]):  # Limit to 10
                # Try to find a key concept and create a question
                words = sentence.split()
                if len(words) > 5:
                    # Create a simple "What is X?" question
                    key_word = words[0] if words[0].istitle() else "this concept"
                    question = f"What is {key_word}?"
                    flashcards.append(Flashcard(
                        question=question,
                        answer=sentence
                    ))
        
        return flashcards[:15]  # Limit to 15 flashcards max
    
    async def generate_flashcards(self, content: str, num_flashcards: int = 10) -> List[Flashcard]:
        """
        Generate flashcards from content using the existing summarizer model.
        """
        # Clean the input content
        cleaned_content = self._clean_text(content)
        
        if len(cleaned_content.split()) < 20:
            raise ValueError("Content too short for flashcard generation")
        
        # Use a simple but effective approach - create flashcards directly from content
        loop = asyncio.get_running_loop()
        
        def generate_summary():
            # Generate a summary that we can use to create flashcards
            summary_prompt = f"Summarize the key points from this text in {num_flashcards} clear sentences: {cleaned_content}"
            result = self.summarizer.pipe(
                summary_prompt,
                max_length=512,
                min_length=100,
                truncation=True,
                num_beams=4,
                length_penalty=1.0
            )[0]["summary_text"]
            return result
        
        summary_response = await loop.run_in_executor(None, generate_summary)
        
        # Split summary into sentences
        summary_sentences = re.split(r'[.!?]+', summary_response)
        summary_sentences = [s.strip() for s in summary_sentences if len(s.strip()) > 20]
        
        # Also get sentences from original content
        original_sentences = re.split(r'[.!?]+', cleaned_content)
        original_sentences = [s.strip() for s in original_sentences if len(s.strip()) > 30]
        
        # Combine sentences, prioritizing summary sentences
        all_sentences = summary_sentences + original_sentences
        
        flashcards = []
        
        # Create flashcards from sentences
        for i, sentence in enumerate(all_sentences[:num_flashcards]):
            # Clean the sentence
            sentence = sentence.strip()
            if not sentence:
                continue
                
            # Extract key terms for question generation
            words = sentence.split()
            
            # Find the most important term (usually the first capitalized word)
            key_term = None
            for word in words:
                # Look for capitalized words that are likely topics
                if (word[0].isupper() and len(word) > 3 and 
                    word.lower() not in ['the', 'this', 'that', 'these', 'those', 'what', 'when', 'where', 'which', 'who', 'why', 'how', 'there', 'during', 'which', 'where', 'extract', 'important', 'sentences', 'text', 'could', 'used', 'educational', 'flashcards', 'focus', 'definitions', 'processes', 'concepts']):
                    key_term = word
                    break
            
            # If no good term found, use the first significant word
            if not key_term:
                for word in words:
                    if len(word) > 4 and word.lower() not in ['the', 'this', 'that', 'these', 'those', 'what', 'when', 'where', 'which', 'who', 'why', 'how', 'there', 'during', 'which', 'where', 'extract', 'important', 'sentences', 'text', 'could', 'used', 'educational', 'flashcards', 'focus', 'definitions', 'processes', 'concepts']:
                        key_term = word.capitalize()
                        break
            
            if not key_term:
                key_term = "this topic"
            
            # Create a simple, clear question
            question = f"What is {key_term}?"
            
            flashcards.append(Flashcard(
                question=question,
                answer=sentence
            ))
        
        # Remove duplicates and limit
        unique_flashcards = []
        seen_questions = set()
        for card in flashcards:
            if card.question not in seen_questions:
                unique_flashcards.append(card)
                seen_questions.add(card.question)
        
        return unique_flashcards[:num_flashcards] 