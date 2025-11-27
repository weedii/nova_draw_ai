import time
import base64
from pathlib import Path
from openai import OpenAI
from typing import Tuple, Any
from src.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
import io
import subprocess
import tempfile
from src.core.logger import logger


class AudioService:
    """Service for transcribing audio files and enhancing them into drawing prompts"""

    def __init__(self):
        logger.info("Initializing AudioService...")

        if not settings.OPENAI_API_KEY:
            logger.error("OpenAI API key is missing")
            raise ValueError("OpenAI API key is required for audio transcription")

        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
        self.whisper_model = "whisper-1"
        self.enhancement_model = "gpt-4o"

        # Create audio storage directory
        self.audio_storage = Path("storage/audio")
        self.audio_storage.mkdir(parents=True, exist_ok=True)

        logger.info(f"AudioService initialized successfully")
        logger.info(f"Using Whisper model: {self.whisper_model}")
        logger.info(f"Using enhancement model: {self.enhancement_model}")

    def convert_audio_to_mp3(
        self, audio_data: bytes, original_filename: str
    ) -> Tuple[bytes, str]:
        """
        Convert audio to MP3 format if needed.
        Uses pydub with imageio-ffmpeg for conversion.

        Args:
            audio_data: Original audio file data
            original_filename: Original filename

        Returns:
            Tuple of (converted_audio_data, new_filename)
        """
        file_ext = Path(original_filename).suffix.lower().replace(".", "")

        # Whisper supported formats
        whisper_formats = [
            "flac",
            "m4a",
            "mp3",
            "mp4",
            "mpeg",
            "mpga",
            "oga",
            "ogg",
            "wav",
            "webm",
        ]

        # If already supported, return as-is
        if file_ext in whisper_formats:
            logger.info(f"✅ Audio format '{file_ext}' is supported by Whisper")
            return audio_data, original_filename

        # Convert unsupported formats (like AAC) to MP3
        logger.info(f"🔄 Converting '{file_ext}' to MP3...")

        try:
            import imageio_ffmpeg

            # Get ffmpeg path from imageio
            ffmpeg_path = imageio_ffmpeg.get_ffmpeg_exe()
            logger.info(f"📦 Using ffmpeg from: {ffmpeg_path}")

            # Create temporary files for conversion
            with tempfile.NamedTemporaryFile(
                suffix=f".{file_ext}", delete=False
            ) as input_file:
                input_file.write(audio_data)
                input_path = input_file.name

            with tempfile.NamedTemporaryFile(
                suffix=".mp3", delete=False
            ) as output_file:
                output_path = output_file.name

            try:
                # Use ffmpeg directly to convert
                command = [
                    ffmpeg_path,
                    "-i",
                    input_path,
                    "-vn",  # No video
                    "-ar",
                    "44100",  # Audio sample rate
                    "-ac",
                    "2",  # Audio channels
                    "-b:a",
                    "128k",  # Audio bitrate
                    "-f",
                    "mp3",  # Output format
                    output_path,
                    "-y",  # Overwrite output file
                    "-loglevel",
                    "error",  # Only show errors
                ]

                logger.info(f"🔧 Running ffmpeg conversion...")
                result = subprocess.run(
                    command, capture_output=True, text=True, timeout=30
                )

                if result.returncode != 0:
                    logger.error(f"❌ ffmpeg error: {result.stderr}")
                    raise ValueError(f"ffmpeg conversion failed: {result.stderr}")

                # Read converted file
                with open(output_path, "rb") as f:
                    converted_data = f.read()

                new_filename = Path(original_filename).stem + ".mp3"

                logger.info(
                    f"✅ Conversion successful: {len(audio_data)} → {len(converted_data)} bytes"
                )

                return converted_data, new_filename

            finally:
                # Clean up temporary files
                try:
                    Path(input_path).unlink()
                    Path(output_path).unlink()
                except:
                    pass

        except Exception as e:
            logger.error(f"❌ Conversion failed: {str(e)}")
            raise ValueError(
                f"Failed to convert audio format '{file_ext}' to MP3. Error: {str(e)}"
            )

    def transcribe_audio(
        self, audio_data: bytes, language: str = "en", filename: str = "audio.mp3"
    ) -> Tuple[str, float]:
        """
        Transcribe audio file to text using OpenAI Whisper.

        Args:
            audio_data: Audio file data in bytes
            language: Language code ('en' or 'de')
            filename: Original filename (for saving temporarily)

        Returns:
            Tuple of (transcribed_text, transcription_time)
        """
        logger.info(
            f"🎤 Starting audio transcription for: '{filename}' (language: {language})"
        )
        start_time = time.time()

        try:
            # Convert to supported format if needed
            audio_data, filename = self.convert_audio_to_mp3(audio_data, filename)

            # Save audio temporarily for Whisper API
            temp_audio_path = self.audio_storage / f"temp_{int(time.time())}_{filename}"
            logger.info(f"📁 Saving temporary audio file: {temp_audio_path.name}")

            with open(temp_audio_path, "wb") as f:
                f.write(audio_data)

            # Transcribe using Whisper with language parameter for better accuracy
            logger.info(f"🔄 Calling Whisper API (model: {self.whisper_model})...")
            with open(temp_audio_path, "rb") as audio_file:
                transcript = self.client.audio.transcriptions.create(
                    model=self.whisper_model,
                    file=audio_file,
                    language=language,  # 'en' or 'de' - helps Whisper understand the audio better
                    response_format="text",
                    prompt=None,  # Optional: can add context hints here if needed
                )

            duration = time.time() - start_time
            logger.info(f"✅ Transcription completed in {duration:.2f}s")
            logger.info(f"📝 Transcribed text: '{transcript.strip()}'")

            # Clean up temporary file
            try:
                temp_audio_path.unlink()
                logger.info(f"🗑️ Temporary file cleaned up")
            except Exception as e:
                logger.warning(f"⚠️ Could not delete temporary audio file: {e}")

            return transcript.strip(), duration

        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"❌ Transcription failed after {duration:.2f}s: {str(e)}")
            # Clean up on error
            try:
                if temp_audio_path.exists():
                    temp_audio_path.unlink()
            except:
                pass
            raise ValueError(f"Audio transcription failed: {str(e)}")

    def enhance_prompt(
        self, transcribed_text: str, language: str = "en"
    ) -> Tuple[str, float]:
        """
        Enhance transcribed text into a good drawing prompt.

        Args:
            transcribed_text: The transcribed text from audio
            language: Language code ('en' or 'de')

        Returns:
            Tuple of (enhanced_prompt, enhancement_time)
        """
        logger.info(f"🔄 Starting prompt enhancement for: '{transcribed_text}'")
        start_time = time.time()

        try:
            # Create enhancement prompt based on language
            if language == "de":
                system_prompt = """
                Du bist ein Experte darin, natürliche Sprache in klare, detaillierte Zeichenaufforderungen für ein Kinder-Zeichen-App umzuwandeln.
                
                Deine Aufgabe ist es, die vom Benutzer gesprochene Eingabe in eine präzise, beschreibende Zeichenaufforderung zu verwandeln, die:
                - Klar und spezifisch ist
                - Für Kinder im Alter von 4-7 Jahren geeignet ist
                - Visuell beschreibend ist
                - Einfache, zeichenbare Objekte fokussiert
                - Positiv und ermutigend ist
                
                REGELN:
                - Wenn der Benutzer ein Objekt oder Tier erwähnt, mache es zu einer klaren Zeichenaufforderung
                - Füge hilfreiche visuelle Details hinzu (z.B. "glücklich", "bunt", "groß")
                - Halte es einfach - vermeide zu komplexe Szenen
                - Wenn die Eingabe unklar ist, wähle die wahrscheinlichste kinderfreundliche Interpretation
                - Gib NUR die verbesserte Aufforderung zurück, keine Erklärungen
                
                BEISPIELE:
                Eingabe: "Ich möchte einen Hund zeichnen"
                Ausgabe: "Ein freundlicher Hund mit einem wedelnden Schwanz"
                
                Eingabe: "Katze die spielt"
                Ausgabe: "Eine verspielte Katze mit einem Ball"
                
                Eingabe: "Haus mit Baum"
                Ausgabe: "Ein gemütliches Haus mit einem großen Baum daneben"
                """

                user_message = (
                    f"Verwandle dies in eine Zeichenaufforderung: {transcribed_text}"
                )
            else:
                system_prompt = """
                You are an expert at converting natural speech into clear, detailed drawing prompts for a children's drawing app.
                
                Your task is to transform the user's spoken input into a precise, descriptive drawing prompt that is:
                - Clear and specific
                - Appropriate for children aged 4-7
                - Visually descriptive
                - Focused on simple, drawable objects
                - Positive and encouraging
                
                RULES:
                - If the user mentions an object or animal, make it a clear drawing prompt
                - Add helpful visual details (e.g., "happy", "colorful", "big")
                - Keep it simple - avoid overly complex scenes
                - If the input is unclear, choose the most likely child-friendly interpretation
                - Return ONLY the enhanced prompt, no explanations
                
                EXAMPLES:
                Input: "I want to draw a dog"
                Output: "A friendly dog with a wagging tail"
                
                Input: "cat playing"
                Output: "A playful cat with a ball"
                
                Input: "house with tree"
                Output: "A cozy house with a big tree next to it"
                """

                user_message = f"Convert this into a drawing prompt: {transcribed_text}"

            # Call OpenAI API for enhancement
            logger.info(f"🔄 Calling OpenAI API (model: {self.enhancement_model})...")
            response = self.client.chat.completions.create(
                model=self.enhancement_model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                max_tokens=100,
                temperature=0.7,
            )

            duration = time.time() - start_time

            if not response.choices or not response.choices[0].message.content:
                logger.error("❌ Empty response from OpenAI API")
                raise ValueError("Empty response from OpenAI API")

            enhanced_prompt = response.choices[0].message.content.strip()
            logger.info(f"✅ Enhancement completed in {duration:.2f}s")
            logger.info(f"✨ Enhanced prompt: '{enhanced_prompt}'")

            return enhanced_prompt, duration

        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"❌ Enhancement failed after {duration:.2f}s: {str(e)}")
            raise ValueError(f"Prompt enhancement failed: {str(e)}")

    def get_audio_info(self, audio_data: bytes, filename: str = "audio.mp3") -> str:
        """
        Get audio file information for logging.

        Args:
            audio_data: Audio file data
            filename: Original filename

        Returns:
            Formatted string with audio info
        """
        size_kb = len(audio_data) / 1024
        size_mb = size_kb / 1024

        if size_mb >= 1:
            size_str = f"{size_mb:.2f}MB"
        else:
            size_str = f"{size_kb:.2f}KB"

        return f"filename={filename}, size={size_str}"

    def process_audio_to_prompt(
        self, audio_data: bytes, language: str = "en", filename: str = "audio.mp3"
    ) -> Tuple[str, str, float]:
        """
        Complete pipeline: transcribe audio and enhance to drawing prompt.

        Args:
            audio_data: Audio file data in bytes
            language: Language code ('en' or 'de')
            filename: Original filename

        Returns:
            Tuple of (transcribed_text, enhanced_prompt, total_processing_time)
        """
        logger.info(f"🎯 Starting complete audio-to-prompt pipeline")
        pipeline_start = time.time()

        # Step 1: Transcribe audio
        transcribed_text, transcription_time = self.transcribe_audio(
            audio_data, language, filename
        )

        # Step 2: Enhance to prompt
        enhanced_prompt, enhancement_time = self.enhance_prompt(
            transcribed_text, language
        )

        total_time = time.time() - pipeline_start
        logger.info(
            f"🎉 Pipeline completed in {total_time:.2f}s (transcription: {transcription_time:.2f}s, enhancement: {enhancement_time:.2f}s)"
        )

        return transcribed_text, enhanced_prompt, total_time

    def validate_audio_file(self, audio_data: bytes, content_type: str) -> bool:
        """
        Validate audio file.

        Args:
            audio_data: Audio file data
            content_type: MIME type of the file

        Returns:
            True if valid, False otherwise
        """
        # Check file size (max 25MB for Whisper API)
        max_size = 25 * 1024 * 1024  # 25MB
        if len(audio_data) > max_size:
            return False

        # Check content type
        valid_types = [
            "audio/mpeg",  # mp3
            "audio/mp3",
            "audio/wav",
            "audio/wave",
            "audio/x-wav",
            "audio/mp4",
            "audio/m4a",
            "audio/x-m4a",
            "audio/aac",  # aac
            "audio/aacp",
            "audio/x-aac",
            "audio/vnd.dlna.adts",  # AAC ADTS format
            "audio/flac",
            "audio/x-flac",
            "audio/webm",
            "audio/ogg",
            "application/octet-stream",  # Generic binary
        ]

        if content_type not in valid_types:
            return False

        return True

    def get_supported_formats(self) -> dict:
        """
        Get list of supported audio formats.

        Returns:
            Dictionary with supported formats info
        """
        return {
            "formats": ["mp3", "wav", "m4a", "aac", "webm", "ogg", "flac"],
            "max_size_mb": 25,
            "languages": ["en", "de"],
        }
