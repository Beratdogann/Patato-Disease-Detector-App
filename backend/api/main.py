import os
import numpy as np
from fastapi import FastAPI, UploadFile, File
import uvicorn
from io import BytesIO
from PIL import Image
import tensorflow as tf

# ---------- MODEL ----------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "..", "models", "model_1.h5")

print("MODEL PATH:", MODEL_PATH)  # debug
MODEL = tf.keras.models.load_model(MODEL_PATH)
CLASS_NAMES = ["Early_blight", "Late_blight", "Healthy"]
IMAGE_SIZE = (256, 256)  # modeli neye göre eğittiysen ona göre ayarla

app = FastAPI()

@app.get("/ping")
async def ping():
    return {"message": "Hello, I'm berat"}

def read_file_as_image(data) -> np.ndarray:
    image = Image.open(BytesIO(data)).convert("RGB")
    return np.array(image)

def preprocess_image(image: np.ndarray) -> np.ndarray:
    img = tf.image.resize(image, IMAGE_SIZE)
    # img = img / 255.0
    img = np.expand_dims(img, axis=0)  # (1, H, W, C)
    return img

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    print(">>> predict() ÇALIŞTI, dosya:", file.filename)  # debug

    image = read_file_as_image(await file.read())
    input_batch = preprocess_image(image)

    preds = MODEL.predict(input_batch)
    print(">>> raw preds:", preds)  # debug

    predicted_index = int(np.argmax(preds[0]))
    predicted_class = CLASS_NAMES[predicted_index]
    confidence = float(np.max(preds[0]))

    return {
        "filename": file.filename,
        "prediction": predicted_class,
        "confidence": confidence,
        "class_index": predicted_index,
        "shape": str(image.shape),
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=9000, reload=True)
