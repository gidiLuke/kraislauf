from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from app.models.chat import ChatRequest, ChatResponse
from app.services.langchain_mock import get_chat_response, analyze_image
from app.core.logging import logger

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Process a chat request and return a response.
    """
    logger.info(f"Received chat request: {request.message[:50]}...")

    try:
        response = get_chat_response(request.message, request.history)
        return ChatResponse(response=response)
    except Exception as e:
        logger.error(f"Error processing chat request: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Error processing request: {str(e)}"
        )


@router.post("/upload", response_model=ChatResponse)
async def upload_image(file: UploadFile = File(...)):
    """
    Process an uploaded image for recycling analysis.
    """
    logger.info(f"Received image upload: {file.filename}")

    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        content = await file.read()
        response = analyze_image(content, file.filename)
        return ChatResponse(response=response)
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")
