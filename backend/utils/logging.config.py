"""
Logging Configuration Module

This module provides custom logging configuration for the PiQuick Objects project.
It defines color-coded log levels, a custom SUCCESS log level, and a formatter
that applies ANSI colors to log output, enhancing log readability in terminals.
"""

import logging
import sys

# ANSI escape colors
COLORS = {
    "DEBUG": "\033[93m",     # yellow
    "INFO": "\033[94m",      # blue
    "WARNING": "\033[95m",   # purple-ish
    "ERROR": "\033[91m",     # red
    "CRITICAL": "\033[1;91m",# red, bold
    "SUCCESS": "\033[92m",   # green
    "RESET": "\033[0m",      # reset
}

# New log level: SUCCESS
SUCCESS_LEVEL_NUM = 25
logging.addLevelName(SUCCESS_LEVEL_NUM, "SUCCESS")

def success(self, message, *args, **kwargs):
    """
    Log a message with SUCCESS level.
    
    Args:
        message: The message to log
        *args: Variable arguments passed to the logging method
        **kwargs: Keyword arguments passed to the logging method
    """
    if self.isEnabledFor(SUCCESS_LEVEL_NUM):
        self._log(SUCCESS_LEVEL_NUM, message, args, **kwargs)
logging.Logger.success = success


class ColoredFormatter(logging.Formatter):
    """
    Custom log formatter that adds colors to log level names in terminal output.
    """
    def format(self, record):
        """
        Format the log record with colors.
        
        Args:
            record: The log record to format
            
        Returns:
            str: The formatted log message with colored level name
        """
        levelname = record.levelname
        color = COLORS.get(levelname, "")
        reset = COLORS["RESET"]
        # Color only the [LEVELNAME] part
        record.levelname = f"{color}{record.levelname}{reset}"
        return super().format(record)


def setup_custom_logger(name: str) -> logging.Logger:
    """
    Create and configure a logger with colored output.
    
    Args:
        name: Name of the logger
        
    Returns:
        logging.Logger: Configured logger instance with colored formatter
    """
    formatter = ColoredFormatter(
        "[%(asctime)s] [%(levelname)s] [%(name)s]: %(message)s",
        "%Y-%m-%d %H:%M:%S"
    )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    logger.addHandler(handler)
    logger.propagate = False

    return logger