from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import HTMLResponse
from pathlib import Path
import uuid
import mimetypes

app = FastAPI(title="Consent Photo API")
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
MAX_BYTES = 15 * 1024 * 1024

ALLOWED = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}

@app.get("/")
def gallery():
    items = []
    for p in sorted(UPLOAD_DIR.iterdir(), reverse=True):
        if p.is_file():
            items.append(f'<div><img src="/files/{p.name}" loading="lazy"><p>{p.name}</p></div>')
    return HTMLResponse("""<!doctype html><html><head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Consent Photo Gallery</title>
    <style>
    body{font-family:system-ui;margin:24px;background:#111;color:#eee}
    .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px}
    img{width:100%;aspect-ratio:1;object-fit:cover;border-radius:12px;background:#222}
    p{font-size:12px;word-break:break-all}
    </style></head><body><h1>Uploaded Photos</h1>
    <div class="grid">""" + "".join(items) + "</div></body></html>")

@app.get("/files/{name}")
def file_path(name: str):
    p = UPLOAD_DIR / Path(name).name
    if not p.exists() or not p.is_file():
        raise HTTPException(404, "Not found")
    from fastapi.responses import FileResponse
    return FileResponse(p)

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    if file.content_type not in ALLOWED:
        raise HTTPException(415, "Only image files are accepted")

    data = await file.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise HTTPException(413, "File too large")

    ext = mimetypes.guess_extension(file.content_type) or ".img"
    name = f"{uuid.uuid4().hex}{ext}"
    (UPLOAD_DIR / name).write_bytes(data)
    return {"ok": True, "filename": name}
