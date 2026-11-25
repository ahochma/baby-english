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

The three ELEVENLABS_* values can also live in scripts/.env (gitignored).

Examples:
  python3 scripts/generate_voice.py --engine say
  ELEVENLABS_API_KEY=... ELEVENLABS_VOICE_EN=... ELEVENLABS_VOICE_HE=... \\
      python3 scripts/generate_voice.py --engine elevenlabs
"""
import argparse, json, os, subprocess, sys, tempfile, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "ios", "App", "App", "Audio")
LINES = json.load(open(os.path.join(ROOT, "scripts", "voice_lines.json")))
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

def original_word_lines():
    """The 40 original word clips (.mp3) plus the celebration cheer, so they can be
    regenerated under a commercial-licensed plan. Labels come from Models.swift."""
    import re
    models = open(os.path.join(ROOT, "ios", "App", "App", "Models.swift")).read()
    labels = dict(re.findall(r'WordItem\(id:"(\w+)",\s*label:"([^"]+)"', models))
    lines = {}
    for f in sorted(os.listdir(AUDIO)):
        if f.endswith(".mp3"):
            cid = f[:-4]
            if cid in labels: lines[cid] = labels[cid]
    lines["celebration"] = "Yaaay! Great job!"
    return lines

def elevenlabs_mp3(text, lang, out_base):
    """Same as elevenlabs() but keeps .mp3 (used for the original word files)."""
    key = os.environ["ELEVENLABS_API_KEY"]
    voice = os.environ["ELEVENLABS_VOICE_" + lang.upper()]
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": "eleven_multilingual_v2"}).encode(),
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(req) as r, open(out_base + ".mp3", "wb") as f:
        f.write(r.read())

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
    ap.add_argument("--trim-only", action="store_true", help="only trim silence of existing voice .m4a clips")
    ap.add_argument("--originals", action="store_true",
                    help="also regenerate the original word .mp3 clips + celebration (elevenlabs only)")
    a = ap.parse_args()
    if a.trim_only:
        ids = [cid for lang in ("en", "he") for cid in LINES[lang]]
        for cid in ids:
            p = os.path.join(AUDIO, cid + ".m4a")
            if os.path.exists(p): trim_silence(p)
        print(f"trimmed {len(ids)} clips"); return
    load_env_file()
    if a.engine == "elevenlabs":
        missing = [k for k in ("ELEVENLABS_API_KEY", "ELEVENLABS_VOICE_EN", "ELEVENLABS_VOICE_HE") if not os.environ.get(k)]
        if missing:
            sys.exit("missing " + ", ".join(missing) + " (set them in scripts/.env, see scripts/.env.example)")
    only = set(a.only.split(",")) if a.only else None
    fn = say if a.engine == "say" else elevenlabs
    n = 0
    for lang in ("en", "he"):
        for cid, text in LINES[lang].items():
            if only and cid not in only: continue
            fn(text, lang, os.path.join(AUDIO, cid)); n += 1
            trim_silence(os.path.join(AUDIO, cid + ".m4a"))
            print(f"  {cid:16} {text}")
    if a.originals and a.engine == "elevenlabs":
        for cid, text in original_word_lines().items():
            if only and cid not in only: continue
            elevenlabs_mp3(text, "en", os.path.join(AUDIO, cid)); n += 1
            print(f"  {cid:16} {text}  (mp3)")
    print(f"done: {n} clips")

if __name__ == "__main__":
    sys.exit(main())
