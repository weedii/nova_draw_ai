"""
Centralized logging configuration for the entire backend application.

This module provides a single, unified logger instance that all backend modules
should use instead of creating their own loggers. This ensures consistent
formatting, log levels, and output across the entire application.

Usage:
    from src.core.logger import logger

    logger.info("Application started")
    logger.error("An error occurred", exc_info=True)
    logger.debug("Debug information")
"""

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

# Create logs directory if it doesn't exist
LOGS_DIR = Path("logs")
LOGS_DIR.mkdir(exist_ok=True)

# Define log format
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

# Create the logger
logger = logging.getLogger("nova_draw_ai")
logger.setLevel(logging.DEBUG)

# Remove any existing handlers to avoid duplicates
logger.handlers.clear()

# Console Handler (for development and production)
# NOTE: The console output might still show errors in Windows PowerShell/CMD
# unless you run 'chcp 65001' in your terminal before execution.
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
console_formatter = logging.Formatter(LOG_FORMAT, datefmt=DATE_FORMAT)
console_handler.setFormatter(console_formatter)

logger.addHandler(console_handler)

# File Handler (for persistent logging)
file_handler = RotatingFileHandler(
    LOGS_DIR / "app.log",
    maxBytes=10 * 1024 * 1024,  # 10 MB
    backupCount=5,  # Keep 5 backup files
    encoding="utf-8",  # <--- FIXED: Added explicit UTF-8 encoding for emojis
)
file_handler.setLevel(logging.DEBUG)
file_formatter = logging.Formatter(LOG_FORMAT, datefmt=DATE_FORMAT)
file_handler.setFormatter(file_formatter)
logger.addHandler(file_handler)

# Error File Handler (for errors only)
error_handler = RotatingFileHandler(
    LOGS_DIR / "error.log",
    maxBytes=10 * 1024 * 1024,  # 10 MB
    backupCount=5,  # Keep 5 backup files
    encoding="utf-8",  # <--- FIXED: Added explicit UTF-8 encoding for emojis
)
error_handler.setLevel(logging.ERROR)
error_formatter = logging.Formatter(LOG_FORMAT, datefmt=DATE_FORMAT)
error_handler.setFormatter(error_formatter)
logger.addHandler(error_handler)

# Prevent propagation to root logger
logger.propagate = False


def get_module_logger(module_name: str) -> logging.Logger:
    """
    Get a logger for a specific module.

    This function creates a child logger with the module name, which will
    inherit the configuration from the main logger but allow for module-specific
    filtering if needed in the future.

    Args:
        module_name: The name of the module (typically __name__)

    Returns:
        A logger instance for the module

    Example:
        logger = get_module_logger(__name__)
        logger.info("Module initialized")
    """

    return logging.getLogger(f"nova_draw_ai.{module_name}")


# Export the main logger for direct use
__all__ = ["logger", "get_module_logger"]
