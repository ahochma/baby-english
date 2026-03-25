#!/bin/bash
# Generates high-quality US English audio files for all 30 words
# Uses macOS built-in Samantha voice (en-US) via `say` + `afconvert`
set -e

OUTDIR="$(dirname "$0")/../public/sounds/words"
mkdir -p "$OUTDIR"

SLUGS=(dog cat bird fish cow duck elephant lion frog rabbit
       red blue green yellow orange purple pink white black brown
       apple banana milk bread egg strawberry carrot cake grapes)

WORDS=(Dog Cat Bird Fish Cow Duck Elephant Lion Frog Rabbit
       Red Blue Green Yellow Orange Purple Pink White Black Brown
       Apple Banana Milk Bread Egg Strawberry Carrot Cake Grapes)

for i in "${!SLUGS[@]}"; do
  slug="${SLUGS[$i]}"
  word="${WORDS[$i]}"
  tmpfile="/tmp/baby_${slug}.aiff"
  outfile="${OUTDIR}/${slug}.m4a"
  echo "  Generating: \"$word\" → ${slug}.m4a"
  say -v Samantha -r 160 -o "$tmpfile" "$word"
  afconvert -f m4af -d aac "$tmpfile" "$outfile"
  rm -f "$tmpfile"
done

echo ""
echo "✓ Generated ${#SLUGS[@]} audio files in public/sounds/words/"
