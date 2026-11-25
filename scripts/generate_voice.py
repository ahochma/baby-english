#!/usr/bin/env python3
"""Generate every spoken clip in the app from voice_lines.json.

Two engines:
  --engine say          macOS built-in voices (rough placeholders, no account needed)
  --engine elevenlabs   final quality (ElevenLabs eleven_v3 for both languages);
                        needs ELEVENLABS_API_KEY, ELEVENLABS_VOICE_EN and
                        ELEVENLABS_VOICE_HE, in the environment or in scripts/.env

Lines may start with a v3 audio tag such as [excited] or [curious]; it sets the
delivery and is not spoken (the say engine drops it). Whole sentences are one
clip, so nothing is stitched mid-sentence. Every clip is written as
ios/App/App/Audio/<id>.m4a and trimmed of leading/trailing silence.

Examples:
  python3 scripts/generate_voice.py --engine elevenlabs
  python3 scripts/generate_voice.py --engine elevenlabs --only dog,ask_dog
"""
import argparse, json, os, re, subprocess, sys, tempfile, urllib.request
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "ios", "App", "App", "Audio")
LINES = json.load(open(os.path.join(ROOT, "scripts", "voice_lines.json")))
TAG = re.compile(r"\[[^\]]*\]\s*")
ENV_FILE = os.path.join(ROOT, "scripts", ".env")   # gitignored; KEY=value lines

def load_env_file():
    """Read scripts/.env so the API key never has to be typed on the command line."""
    if not os.path.exists(ENV_FILE):
        return
    for line in open(ENV_FILE):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def say(text, lang, out_base):
    voice = {"en": "Flo (English (US))", "he": "Carmit"}[lang]
    with tempfile.TemporaryDirectory() as d:
        aiff = os.path.join(d, "x.aiff")
        subprocess.run(["say", "-v", voice, "-r", "165" if lang == "en" else "175", "-o", aiff, TAG.sub("", text)], check=True)
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", aiff, out_base + ".m4a"], check=True)

def elevenlabs(text, lang, out_base):
    key = os.environ["ELEVENLABS_API_KEY"]
    voice = os.environ["ELEVENLABS_VOICE_" + lang.upper()]
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": "eleven_v3"}).encode(),
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with tempfile.TemporaryDirectory() as d:
        mp3 = os.path.join(d, "x.mp3")
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=90) as r, open(mp3, "wb") as f:
                    f.write(r.read())
                break
            except urllib.error.HTTPError as e:
                if e.code != 429 or attempt == 2: raise
                import time; time.sleep(3 * (attempt + 1))
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", mp3, out_base + ".m4a"], check=True)

def trim_silence(m4a_path, lead_pad=0.04, tail_pad=0.12, threshold=0.04):
    """Cut leading/trailing silence so sequences like "כלב… Dog!" stay snappy."""
    import aifc, struct
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "in.aiff"); dst = os.path.join(d, "out.aiff")
        subprocess.run(["afconvert", "-f", "AIFF", "-d", "BEI16@44100", "-c", "1", m4a_path, src], check=True)
        r = aifc.open(src); n = r.getnframes(); raw = r.readframes(n); r.close()
        x = struct.unpack(">%dh" % n, raw)
        win = 441  # 10 ms
        env = [max(abs(v) for v in x[i:i + win]) for i in range(0, max(1, n - win), win)]
        peak = max(env) or 1
        voiced = [i for i, e in enumerate(env) if e > peak * threshold]
        if not voiced:
            return
        start = max(0, voiced[0] * win - int(lead_pad * 44100))
        end = min(n, (voiced[-1] + 1) * win + int(tail_pad * 44100))
        w = aifc.open(dst, "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(44100)
        w.writeframes(raw[start * 2:end * 2]); w.close()
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", dst, m4a_path], check=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--engine", choices=["say", "elevenlabs"], required=True)
    ap.add_argument("--only", help="comma-separated ids to (re)generate")
    ap.add_argument("--trim-only", action="store_true", help="only trim silence of existing clips")
    ap.add_argument("--jobs", type=int, default=3, help="parallel requests (ElevenLabs Starter allows 3)")
    a = ap.parse_args()
    jobs = [(lang, cid, text) for lang in ("en", "he") for cid, text in LINES[lang].items()
            if not a.only or cid in a.only.split(",")]
    if a.trim_only:
        for _, cid, _ in jobs:
            p = os.path.join(AUDIO, cid + ".m4a")
            if os.path.exists(p): trim_silence(p)
        print(f"trimmed {len(jobs)} clips"); return
    load_env_file()
    if a.engine == "elevenlabs":
        missing = [k for k in ("ELEVENLABS_API_KEY", "ELEVENLABS_VOICE_EN", "ELEVENLABS_VOICE_HE") if not os.environ.get(k)]
        if missing:
            sys.exit("missing " + ", ".join(missing) + " (set them in scripts/.env, see scripts/.env.example)")
    fn = say if a.engine == "say" else elevenlabs

    def one(job):
        lang, cid, text = job
        fn(text, lang, os.path.join(AUDIO, cid))
        trim_silence(os.path.join(AUDIO, cid + ".m4a"))
        print(f"  {cid:20} {text}", flush=True)

    with ThreadPoolExecutor(max_workers=max(1, a.jobs)) as pool:
        list(pool.map(one, jobs))
    print(f"done: {len(jobs)} clips")

if __name__ == "__main__":
    sys.exit(main())
