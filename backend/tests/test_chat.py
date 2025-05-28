import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test the root endpoint returns the expected response."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to kraislauf API"}


def test_health_check():
    """Test the health check endpoint returns healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_chat_endpoint():
    """Test the chat endpoint returns a response."""
    request_data = {"message": "How do I recycle plastic bottles?", "history": []}
    response = client.post("/api/chat", json=request_data)
    assert response.status_code == 200
    assert "response" in response.json()
    assert len(response.json()["response"]) > 0
