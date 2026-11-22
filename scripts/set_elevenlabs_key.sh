#!/bin/bash
# Saves ElevenLabs settings to scripts/.env (gitignored, owner-only permissions).
# The key is read with hidden input and is never printed.
set -euo pipefail
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"
umask 077
echo "Baby English: ElevenLabs setup"
read -r -s -p "Paste your ElevenLabs API key (input hidden), then Enter: " KEY; echo
[ -z "$KEY" ] && { echo "No key entered, nothing saved."; exit 1; }
read -r -p "Voice ID for English (voice of the original word clips): " VEN
read -r -p "Voice ID for Hebrew (Enter = same as English): " VHE
VHE="${VHE:-$VEN}"
{
  echo "ELEVENLABS_API_KEY=$KEY"
  echo "ELEVENLABS_VOICE_EN=$VEN"
  echo "ELEVENLABS_VOICE_HE=$VHE"
} > "$ENV_FILE"
chmod 600 "$ENV_FILE"
unset KEY
echo "Saved to scripts/.env (only your user can read it; git ignores it)."
echo "Tell Claude: \"key saved\"."
