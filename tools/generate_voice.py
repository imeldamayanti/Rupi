#!/usr/bin/env python3
"""Generate the app's spoken lines with ElevenLabs.

Reads BacaUang2/Resources/Voice/voice_lines.json and writes one <id>.mp3 per line
next to it. The API key comes from the ELEVENLABS_API_KEY environment variable and
is never stored in the repo or the app.

    ELEVENLABS_API_KEY=... python3 tools/generate_voice.py [--force] [--voice VOICE_ID]
"""
import argparse, json, os, sys, urllib.request, urllib.error
from pathlib import Path

VOICE_DIR = Path(__file__).resolve().parent.parent / "BacaUang2" / "Resources" / "Voice"
DEFAULT_VOICE = "k5eTzx1VYYlp6BE39Qrj"  # Aita, Indonesian, informative
MODEL = "eleven_multilingual_v2"

def synth(key, voice, text):
    body = json.dumps({
        "text": text,
        "model_id": MODEL,
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75},
    }).encode()
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=body,
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="regenerate files that already exist")
    ap.add_argument("--voice", default=DEFAULT_VOICE)
    args = ap.parse_args()

    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("ELEVENLABS_API_KEY is not set")

    lines = json.loads((VOICE_DIR / "voice_lines.json").read_text())
    for line_id, text in lines.items():
        out = VOICE_DIR / f"{line_id}.mp3"
        if out.exists() and not args.force:
            print(f"skip   {line_id}")
            continue
        try:
            out.write_bytes(synth(key, args.voice, text))
        except urllib.error.HTTPError as e:
            sys.exit(f"{line_id}: HTTP {e.code} {e.read().decode(errors='replace')[:200]}")
        print(f"wrote  {line_id}  ({out.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
