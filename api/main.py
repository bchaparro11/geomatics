from python_terraform import Terraform
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


def create_mongodb_cluster(word: str) -> str:

    terraform = Terraform(working_dir="/path/to/my/terraform/project")
    
    terraform.init()
    
    print(terraform.plan())
    
    print(terraform.apply(skip_plan=True))


@app.get("/")
def read_root():
    return {"It's Working": "Keep Coding on Geomatics-API!"}


@app.get("/word/{word}")
def read_word(word: str):
    return create_mongodb_cluster(word)