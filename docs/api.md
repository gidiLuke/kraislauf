# kraislauf API Documentation

## Base URL

Development: `http://localhost:8000`
Production: `https://kraislauf-api.azurecontainerapps.io`

## Authentication

Currently, the API is open for public access. Future versions may implement authentication for admin features.

## Endpoints

### Health Check

```
GET /health
```

Returns the health status of the API.

**Response**

```json
{
  "status": "healthy"
}
```

### Chat

```
POST /api/chat
```

Send a message to the recycling assistant.

**Request Body**

```json
{
  "message": "Can I recycle plastic bottles?",
  "history": [
    {
      "role": "user",
      "content": "Hello"
    },
    {
      "role": "assistant",
      "content": "Hi there! How can I help you with recycling today?"
    }
  ],
  "options": {}
}
```

**Response**

```json
{
  "response": "Yes, most plastic bottles (especially PET #1 and HDPE #2) are recyclable in curbside programs. Make sure to empty and rinse them before recycling."
}
```

### Image Upload

```
POST /api/upload
```

Upload an image of an item to get recycling guidance.

**Request**

Multipart form data with a file field named `file`.

**Response**

```json
{
  "response": "This appears to be a plastic bottle. Most plastic bottles (especially PET #1 and HDPE #2) are recyclable in curbside programs. Make sure to empty and rinse it before recycling."
}
```

## Error Handling

The API returns appropriate HTTP status codes:

- `200 OK`: Request successful
- `400 Bad Request`: Invalid input
- `500 Internal Server Error`: Server-side error

Error responses include a detail message:

```json
{
  "detail": "Error message describing the issue"
}
```

## Rate Limiting

Currently, there are no rate limits implemented. Future versions may include rate limiting for public APIs.
