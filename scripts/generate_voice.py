#!/usr/bin/env python3
"""Generate the app's extra voice clips listed in voice_lines.json.

Two engines:
  --engine say          macOS built-in voices (temporary placeholders, no account needed)
  --engine elevenlabs   final quality; needs these environment variables:
                          ELEVENLABS_API_KEY
                          ELEVENLABS_VOICE_EN   voice id used for the original word clips
                          ELEVENLABS_VOICE_HE   a Hebrew-capable voice id (can be the same)
                        English uses eleven_multilingual_v2, Hebrew uses eleven_v3.

Both engines write ios/App/App/Audio/<id>.m4a, so running the ElevenLabs
engine later simply overwrites the placeholders in place. The files are
already in the Xcode project, so no project change is needed.

Examples:
  python3 scripts/generate_voice.py --engine say
  ELEVENLABS_API_KEY=... ELEVENLABS_VOICE_EN=... ELEVENLABS_VOICE_HE=... \\
      python3 scripts/generate_voice.py --engine elevenlabs
"""
import argparse, json, os, subprocess, sys, tempfile, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "ios", "App", "App", "Audio")
LINES = json.load(open(os.path.join(ROOT, "scripts", "voice_lines.json")))

def say(text, lang, out_base):
    voice = {"en": "Flo (English (US))", "he": "Carmit"}[lang]
    with tempfile.TemporaryDirectory() as d:
        aiff = os.path.join(d, "x.aiff")
        subprocess.run(["say", "-v", voice, "-r", "165" if lang == "en" else "175", "-o", aiff, text], check=True)
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", aiff, out_base + ".m4a"], check=True)

def elevenlabs(text, lang, out_base):
    key = os.environ["ELEVENLABS_API_KEY"]
    voice = os.environ["ELEVENLABS_VOICE_" + lang.upper()]
    model = "eleven_multilingual_v2" if lang == "en" else "eleven_v3"
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": model}).encode(),
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with tempfile.TemporaryDirectory() as d:
        mp3 = os.path.join(d, "x.mp3")
        with urllib.request.urlopen(req) as r, open(mp3, "wb") as f:
            f.write(r.read())
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", mp3, out_base + ".m4a"], check=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--engine", choices=["say", "elevenlabs"], required=True)
    ap.add_argument("--only", help="comma-separated ids to (re)generate")
    a = ap.parse_args()
    only = set(a.only.split(",")) if a.only else None
    fn = say if a.engine == "say" else elevenlabs
    n = 0
    for lang in ("en", "he"):
        for cid, text in LINES[lang].items():
            if only and cid not in only: continue
            fn(text, lang, os.path.join(AUDIO, cid)); n += 1
            print(f"  {cid:16} {text}")
    print(f"done: {n} clips")

if __name__ == "__main__":
    sys.exit(main())
