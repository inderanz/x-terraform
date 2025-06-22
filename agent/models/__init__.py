"""
AI models package for Terraform Agent.
"""

from .ollama_client import OllamaClient, get_ollama_client, close_ollama_client

__all__ = [
    "OllamaClient",
    "get_ollama_client",
    "close_ollama_client"
] 