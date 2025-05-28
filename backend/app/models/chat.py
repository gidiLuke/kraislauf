from pydantic import BaseModel
from typing import List, Optional, Dict, Any


class ChatMessage(BaseModel):
    """A single chat message with role and content."""

    role: str
    content: str


class ChatRequest(BaseModel):
    """Request format for chat endpoint."""

    message: str
    history: Optional[List[ChatMessage]] = []
    options: Optional[Dict[str, Any]] = {}


class ChatResponse(BaseModel):
    """Response format for chat endpoint."""

    response: str
