import os

def ensure_google_credentials():
    if "GOOGLE_APPLICATION_CREDENTIALS" not in os.environ:
        key_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),  # up from utils/
            "serviceAccountKey.json"
        )
        if os.path.exists(key_path):
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = key_path
        else:
            raise RuntimeError(
                f"❌ serviceAccountKey.json not found at {key_path} and GOOGLE_APPLICATION_CREDENTIALS not set!"
            ) 