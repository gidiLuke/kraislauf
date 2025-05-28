import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatRequest {
  message: string;
  history: ChatMessage[];
  options?: Record<string, any>;
}

export interface ChatResponse {
  response: string;
}

export async function sendChatMessage(request: ChatRequest): Promise<ChatResponse> {
  try {
    const response = await api.post<ChatResponse>('/api/chat', request);
    return response.data;
  } catch (error) {
    console.error('Error sending chat message:', error);
    throw error;
  }
}

export async function uploadImage(file: File): Promise<ChatResponse> {
  try {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await api.post<ChatResponse>('/api/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    
    return response.data;
  } catch (error) {
    console.error('Error uploading image:', error);
    throw error;
  }
}

export default api;