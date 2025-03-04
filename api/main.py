from fastapi import FastAPI

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

origins = [
    "http://localhost:8081",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def create_cluster(database_engine: str) -> str:

    import subprocess
    import os

    terraform_dir = r""+f"{database_engine}"
    terraform_dir = terraform_dir.replace(" ","")
    credentials_path = r""

    env = os.environ.copy()
    env["GOOGLE_APPLICATION_CREDENTIALS"] = credentials_path

    cmd = f'start cmd /k "cd /d \"{terraform_dir}\" && terraform init && terraform destroy -auto-approve"'

    subprocess.Popen(cmd, shell=True, env=env)


@app.get("/")
def read_root():
    return {"It's Working": "Keep Coding on Geomatics-API!"}


@app.get("/engine/{database_engine}")
def read_database_engine(database_engine: str):
    create_cluster(database_engine)
    return {"Executed!": f"Creating {database_engine} cluster"}