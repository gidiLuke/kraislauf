import logging
import sys
from app.core.config import settings


# Configure logging
def setup_logging() -> logging.Logger:
    log_level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)

    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )

    # Set log levels for specific modules
    logging.getLogger("uvicorn").setLevel(log_level)
    logging.getLogger("fastapi").setLevel(log_level)

    logger = logging.getLogger(__name__)
    logger.info(f"Logging configured with level: {settings.LOG_LEVEL}")

    return logger


logger = setup_logging()
