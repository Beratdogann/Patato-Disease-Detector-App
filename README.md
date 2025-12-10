# 🥔 Potato Disease Detector

A small end-to-end project where I detect **potato leaf diseases** using:

- 🐍 **FastAPI** + **TensorFlow** on the backend  
- 📱 **Flutter** on the frontend

The model classifies a leaf image into:

- **Early_blight**
- **Late_blight**
- **Healthy**

> 🎓 Personal project for practicing Computer Vision, REST APIs and Flutter UI.

---

## 🔧 Tech Stack

**Backend**

- Python, FastAPI, Uvicorn
- TensorFlow / Keras (`.h5` model)
- NumPy, Pillow

**Frontend**

- Flutter (Android emulator & Windows desktop)
- `http` package for REST calls
- `image_picker` for selecting images

---

## 📁 Project Structure

```bash
potato-disease-detector/
├─ backend/
│  ├─ main.py                # FastAPI app (ping + predict endpoints)
│  ├─ models/
│  │  └─ model_1.h5          # Trained TensorFlow model
│  └─ requirements.txt       # Python dependencies
│
├─ frontend/
│  ├─ lib/
│  │  └─ main.dart           # Flutter UI + API integration
│  ├─ android/
│  ├─ ios/
│  ├─ web/
│  └─ pubspec.yaml           # Flutter dependencies
│
└─ README.md
