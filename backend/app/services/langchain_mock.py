"""
Mock implementation of LangChain services for development.
This will be replaced with actual LangChain implementation later.
"""

from typing import List, Optional

from app.core.logging import logger
from app.models.chat import ChatMessage


def get_chat_response(message: str, history: Optional[List[ChatMessage]] = None) -> str:
    """
    Mock implementation of chat response using LangChain.

    Args:
        message: The user's message
        history: Chat history

    Returns:
        A string response
    """
    logger.debug(f"Processing chat message: {message}")

    # Mock responses based on keywords in the message
    if "plastic" in message.lower():
        return "Most plastic containers with recycling symbols 1 (PET) and 2 (HDPE) are recyclable in curbside programs. Rinse them before recycling and remove caps if required by your local program."  # noqa: E501
    elif "paper" in message.lower():
        return "Clean paper, newspapers, magazines, and cardboard are recyclable. Avoid recycling paper with food contamination, wax coating, or plastic lamination."  # noqa: E501
    elif "glass" in message.lower():
        return "Glass bottles and jars are generally recyclable. Rinse them and remove caps or lids. Note that some items like windows, mirrors, and drinking glasses are not recyclable in standard programs."  # noqa: E501
    elif "metal" in message.lower() or "aluminum" in message.lower():
        return "Aluminum cans, steel food cans, and clean aluminum foil are recyclable. Make sure they're empty and rinsed before recycling."  # noqa: E501
    elif "electronic" in message.lower() or "e-waste" in message.lower():
        return "Electronic waste should not go in standard recycling bins. Look for e-waste collection events or designated drop-off locations in your area."  # noqa: E501
    else:
        return "I'm here to help with recycling questions! You can ask me about specific materials like plastic, paper, glass, or metal, or upload a photo of an item you're unsure about."  # noqa: E501


def analyze_image(image_content: bytes, filename: str) -> str:
    """
    Mock implementation of image analysis for recycling guidance.

    Args:
        image_content: Binary content of the uploaded image
        filename: Name of the uploaded file

    Returns:
        A string response with recycling guidance
    """
    logger.debug(f"Analyzing image: {filename}")

    # Mock responses based on filename keywords
    if "plastic" in filename.lower() or "bottle" in filename.lower():
        return "This appears to be a plastic bottle. Most plastic bottles (especially PET #1 and HDPE #2) are recyclable in curbside programs. Make sure to empty and rinse it before recycling."  # noqa: E501
    elif "paper" in filename.lower() or "cardboard" in filename.lower():
        return "This looks like paper or cardboard. Clean, dry paper and cardboard are recyclable. Flatten cardboard boxes to save space in your recycling bin."  # noqa: E501
    elif "glass" in filename.lower():
        return "This appears to be glass. Glass bottles and jars are recyclable in most programs. Rinse them before recycling."  # noqa: E501
    elif "can" in filename.lower() or "aluminum" in filename.lower():
        return "This looks like a metal can. Aluminum and steel cans are highly recyclable. Rinse them before placing in your recycling bin."  # noqa: E501
    else:
        return "I've analyzed the image, but I'm not certain what this item is. For accurate recycling guidance, please provide more details about the material or check with your local recycling program."  # noqa: E501
