import logging
import sys

# ANSI escape színek
COLORS = {
    "DEBUG": "\033[93m",     # sárga
    "INFO": "\033[94m",      # kék
    "WARNING": "\033[95m",   # lila-ish
    "ERROR": "\033[91m",     # piros
    "CRITICAL": "\033[1;91m",# piros, vastag
    "SUCCESS": "\033[92m",   # zöld
    "RESET": "\033[0m",      # reset
}

# Új log level: SUCCESS
SUCCESS_LEVEL_NUM = 25
logging.addLevelName(SUCCESS_LEVEL_NUM, "SUCCESS")

def success(self, message, *args, **kwargs):
    if self.isEnabledFor(SUCCESS_LEVEL_NUM):
        self._log(SUCCESS_LEVEL_NUM, message, args, **kwargs)
logging.Logger.success = success


class ColoredFormatter(logging.Formatter):
    def format(self, record):
        levelname = record.levelname
        color = COLORS.get(levelname, "")
        reset = COLORS["RESET"]
        # Színezzük csak a [LEVELNAME] részt
        record.levelname = f"{color}{record.levelname}{reset}"
        return super().format(record)


def setup_custom_logger(name: str) -> logging.Logger:
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