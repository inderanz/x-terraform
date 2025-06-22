"""
Ollama client for local AI model interactions.
"""

import asyncio
import json
import time
from typing import Dict, List, Optional, Any, AsyncGenerator
import aiohttp
import structlog
from ..core.config import get_config
from ..core.exceptions import ModelError

logger = structlog.get_logger(__name__)


class OllamaClient:
    """Client for interacting with Ollama API."""
    
    def __init__(self, host: Optional[str] = None, timeout: Optional[int] = None):
        self.config = get_config()
        self.host = host or self.config.ollama_host
        self.timeout = timeout or self.config.ollama_timeout
        self.session: Optional[aiohttp.ClientSession] = None
        self._available_models: Optional[List[str]] = None
    
    async def __aenter__(self):
        """Async context manager entry."""
        await self.connect()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.disconnect()
    
    async def connect(self):
        """Establish connection to Ollama."""
        if self.session is None:
            timeout = aiohttp.ClientTimeout(total=self.timeout)
            self.session = aiohttp.ClientSession(
                base_url=self.host,
                timeout=timeout,
                headers={"Content-Type": "application/json"}
            )
            logger.info(f"Connected to Ollama at {self.host}")
    
    async def disconnect(self):
        """Close connection to Ollama."""
        if self.session:
            await self.session.close()
            self.session = None
            logger.info("Disconnected from Ollama")
    
    async def health_check(self) -> bool:
        """Check if Ollama is healthy."""
        try:
            await self.connect()
            async with self.session.get("/api/tags") as response:
                return response.status == 200
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False
    
    async def list_models(self) -> List[Dict[str, Any]]:
        """List available models."""
        try:
            await self.connect()
            async with self.session.get("/api/tags") as response:
                if response.status != 200:
                    raise ModelError(f"Failed to list models: {response.status}")
                
                data = await response.json()
                models = data.get("models", [])
                self._available_models = [model["name"] for model in models]
                logger.info(f"Found {len(models)} available models")
                return models
        except Exception as e:
            logger.error(f"Failed to list models: {e}")
            raise ModelError(f"Failed to list models: {e}")
    
    async def is_model_available(self, model_name: str) -> bool:
        """Check if a specific model is available."""
        if self._available_models is None:
            await self.list_models()
        return model_name in (self._available_models or [])
    
    async def pull_model(self, model_name: str) -> bool:
        """Pull a model from Ollama registry."""
        try:
            await self.connect()
            logger.info(f"Pulling model: {model_name}")
            
            async with self.session.post("/api/pull", json={"name": model_name}) as response:
                if response.status != 200:
                    raise ModelError(f"Failed to pull model: {response.status}")
                
                # Stream the response to show progress
                async for line in response.content:
                    if line:
                        try:
                            data = json.loads(line.decode().strip())
                            if "status" in data:
                                logger.info(f"Model pull status: {data['status']}")
                        except json.JSONDecodeError:
                            continue
                
                logger.info(f"Successfully pulled model: {model_name}")
                return True
        except Exception as e:
            logger.error(f"Failed to pull model {model_name}: {e}")
            raise ModelError(f"Failed to pull model {model_name}: {e}")
    
    async def generate(
        self,
        prompt: str,
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        system_prompt: Optional[str] = None,
        **kwargs
    ) -> str:
        """Generate a response from the model."""
        try:
            await self.connect()
            
            model_name = model_name or self.config.agent_model
            temperature = temperature or self.config.temperature
            max_tokens = max_tokens or self.config.max_tokens
            
            # Check if model is available
            if not await self.is_model_available(model_name):
                logger.info(f"Model {model_name} not available, pulling...")
                await self.pull_model(model_name)
            
            payload = {
                "model": model_name,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                    **kwargs
                }
            }
            
            if system_prompt:
                payload["system"] = system_prompt
            
            logger.debug(f"Generating response with model: {model_name}")
            start_time = time.time()
            
            async with self.session.post("/api/generate", json=payload) as response:
                if response.status != 200:
                    raise ModelError(f"Generation failed: {response.status}")
                
                data = await response.json()
                response_text = data.get("response", "")
                
                elapsed_time = time.time() - start_time
                logger.info(f"Generated response in {elapsed_time:.2f}s")
                
                return response_text
                
        except Exception as e:
            logger.error(f"Failed to generate response: {e}")
            raise ModelError(f"Failed to generate response: {e}")
    
    async def generate_stream(
        self,
        prompt: str,
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        system_prompt: Optional[str] = None,
        **kwargs
    ) -> AsyncGenerator[str, None]:
        """Generate a streaming response from the model."""
        try:
            await self.connect()
            
            model_name = model_name or self.config.agent_model
            temperature = temperature or self.config.temperature
            max_tokens = max_tokens or self.config.max_tokens
            
            # Check if model is available
            if not await self.is_model_available(model_name):
                logger.info(f"Model {model_name} not available, pulling...")
                await self.pull_model(model_name)
            
            payload = {
                "model": model_name,
                "prompt": prompt,
                "stream": True,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                    **kwargs
                }
            }
            
            if system_prompt:
                payload["system"] = system_prompt
            
            logger.debug(f"Generating streaming response with model: {model_name}")
            
            async with self.session.post("/api/generate", json=payload) as response:
                if response.status != 200:
                    raise ModelError(f"Streaming generation failed: {response.status}")
                
                async for line in response.content:
                    if line:
                        try:
                            data = json.loads(line.decode().strip())
                            if "response" in data:
                                yield data["response"]
                        except json.JSONDecodeError:
                            continue
                            
        except Exception as e:
            logger.error(f"Failed to generate streaming response: {e}")
            raise ModelError(f"Failed to generate streaming response: {e}")
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> str:
        """Chat with the model using message history."""
        try:
            await self.connect()
            
            model_name = model_name or self.config.agent_model
            temperature = temperature or self.config.temperature
            max_tokens = max_tokens or self.config.max_tokens
            
            # Check if model is available
            if not await self.is_model_available(model_name):
                logger.info(f"Model {model_name} not available, pulling...")
                await self.pull_model(model_name)
            
            payload = {
                "model": model_name,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                    **kwargs
                }
            }
            
            logger.debug(f"Chatting with model: {model_name}")
            
            async with self.session.post("/api/chat", json=payload) as response:
                if response.status != 200:
                    raise ModelError(f"Chat failed: {response.status}")
                
                data = await response.json()
                response_text = data.get("message", {}).get("content", "")
                
                return response_text
                
        except Exception as e:
            logger.error(f"Failed to chat: {e}")
            raise ModelError(f"Failed to chat: {e}")


# Global client instance
_ollama_client: Optional[OllamaClient] = None


async def get_ollama_client() -> OllamaClient:
    """Get the global Ollama client instance."""
    global _ollama_client
    if _ollama_client is None:
        _ollama_client = OllamaClient()
        await _ollama_client.connect()
    return _ollama_client


async def close_ollama_client():
    """Close the global Ollama client instance."""
    global _ollama_client
    if _ollama_client:
        await _ollama_client.disconnect()
        _ollama_client = None 