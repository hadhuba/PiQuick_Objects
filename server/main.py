from fastapi import FastAPI
from routes import filter, picker
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(filter.router, prefix="/filters")
app.include_router(picker.router, prefix="/picker")


#run server with 
# fastapi dev main.py
