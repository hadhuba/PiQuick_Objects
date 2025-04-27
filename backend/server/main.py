"""
FastAPI Server Main Module

This module initializes and configures the FastAPI server for the PiQuick Objects project.
It sets up CORS middleware, defines the root endpoint, and includes routers for filters,
picker, and render functionalities, providing the main entry point for the API service.
"""

from fastapi import FastAPI
import sys
import os
from server.routes import filter_repo, picker_repo, render_repo
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    """
    Root endpoint that returns a simple welcome response.
    
    Returns:
        dict: A simple welcome message object
    """
    return {"PiQuick": "Objects"}

app.include_router(filter_repo.router, prefix="/filters")
app.include_router(picker_repo.router, prefix="/picker")
app.include_router(render_repo.router, prefix="/render")


#run server with 
# fastapi dev server/main.py --host 127.0.0.1 --port 8006
# uvicorn server.main:app --host 127.0.0.1 --port 8006