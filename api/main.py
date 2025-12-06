import numpy as np
from fastapi import FastAPI, UploadFile,File
import uvicorn

#python -m uvicorn api.main:app --host 127.0.0.1 --port 8080 --reload


app = FastAPI()

@app.get("/ping/")
async def ping():
    return {"message": "Hello, I'm here"}

def read_file_as_image(data) -> np.ndarray:
    np.array(Images.open(BytesIO(data)))
    return image

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    image  = read_file_as_image(await file.read())

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080)
