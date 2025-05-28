from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router as api_router
from app.core.config import settings

app = FastAPI(
    title="kraislauf API",
    description="API for the kraislauf application",
    version="0.1.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api")


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "Welcome to kraislauf API. See /docs for API documentation."}


@app.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "healthy"}
