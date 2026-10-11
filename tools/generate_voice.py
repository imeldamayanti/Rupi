#!/usr/bin/env python3
"""Generate the app's spoken lines with ElevenLabs.

Reads BacaUang2/Resources/Voice/voice_lines.json and writes one <id>.mp3 per line
next to it. The API key comes from the ELEVENLABS_API_KEY environment variable and
is never stored in the repo or the app.

    ELEVENLABS_API_KEY=... python3 tools/generate_voice.py [--force] [--voice VOICE_ID]
"""
import argparse, json, os, re, shutil, subprocess, sys, urllib.request, urllib.error
from pathlib import Path

VOICE_DIR = Path(__file__).resolve().parent.parent / "BacaUang2" / "Resources" / "Voice"
DEFAULT_VOICE = "k5eTzx1VYYlp6BE39Qrj"  # Aita, Indonesian, informative
MODEL = "eleven_multilingual_v2"

# High stability + fixed seed keeps the delivery even from clip to clip.
VOICE_SETTINGS = {"stability": 0.8, "similarity_boost": 0.8, "style": 0.0, "use_speaker_boost": True}
SEED = 7

def synth(key, voice, text):
    payload = {
        "text": text,
        "model_id": MODEL,
        "voice_settings": VOICE_SETTINGS,
        "seed": SEED,
    }
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=body,
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()

TARGET_MEAN_DB = -19.0

def _mean_db(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"mean_volume: (-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else None

def polish(path):
    """Trim leading/trailing silence and level every clip to the same loudness,
    so clips don't jump in volume. Needs ffmpeg; skipped with a warning without it."""
    if not shutil.which("ffmpeg"):
        print("warn   ffmpeg not found, clips left unpolished")
        return
    tmp = path.with_suffix(".tmp.mp3")
    trim = ("silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,"
            "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.12,areverse")
    run = lambda *a: subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", *a], check=True)
    run("-i", str(path), "-af", trim, "-c:a", "libmp3lame", "-b:a", "128k", str(tmp))
    gain = TARGET_MEAN_DB - (_mean_db(tmp) or TARGET_MEAN_DB)
    run("-i", str(tmp), "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89", "-c:a", "libmp3lame", "-b:a", "128k", str(path))
    tmp.unlink()

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
            polish(out)
        except urllib.error.HTTPError as e:
            sys.exit(f"{line_id}: HTTP {e.code} {e.read().decode(errors='replace')[:200]}")
        print(f"wrote  {line_id}  ({out.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
