import re
from pathlib import Path
from datetime import datetime


def sanitize_filename(name: str) -> str:
    """
    Sanitize a string to be safe for use as a filename.
    """
    # Remove or replace invalid characters
    sanitized = re.sub(r'[<>:"/\\|?*]', "_", name)
    # Remove leading/trailing spaces and dots
    sanitized = sanitized.strip(" .")
    # Limit length
    sanitized = sanitized[:50] if len(sanitized) > 50 else sanitized
    # Ensure it's not empty
    return sanitized if sanitized else "drawing"


def create_session_folder(subject: str, base_path: Path) -> tuple[Path, str]:
    """
    Create a unique session folder for a drawing session.
    Returns (session_path, session_id)
    """
    # Create folder-friendly name: lowercase and replace spaces with underscores
    folder_subject = subject.lower().replace(" ", "_")
    # Then sanitize for any other invalid characters
    sanitized_subject = sanitize_filename(folder_subject)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    session_id = f"{sanitized_subject}_{timestamp}"
    session_path = base_path / session_id
    session_path.mkdir(parents=True, exist_ok=True)
    return session_path, session_id


def get_session_folder(session_id: str, base_path: Path) -> Path:
    """
    Get the path to an existing session folder.
    """
    session_path = base_path / session_id
    if not session_path.exists():
        raise ValueError(f"Session folder not found: {session_id}")
    return session_path
