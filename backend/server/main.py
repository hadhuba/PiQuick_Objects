from fastapi import FastAPI
from routes import filter_repo, picker_repo, render_repo
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
    return {"Hello": "World"}

app.include_router(filter_repo.router, prefix="/filters")
app.include_router(picker_repo.router, prefix="/picker")
app.include_router(render_repo.router, prefix="/render")


#run server with 
# fastapi dev main.py
