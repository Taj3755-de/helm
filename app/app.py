from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def home():
    env = os.getenv("ENV", "development")
    return f"Hello from Flask in {env} environment!"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
