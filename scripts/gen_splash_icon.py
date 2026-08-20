#!/usr/bin/env python3
"""Generate a splash screen icon using Gemini's image-generation model.

Usage:
    python scripts/gen_splash_icon.py <GEMINI_API_KEY>

Outputs:
    assets/icons/splash_icon.png   (1024×1024 rounded-square icon)
"""

import base64, json, sys, urllib.request, urllib.error

MODEL = "gemini-2.0-flash-preview-image-generation"
API_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}"
    f":generateContent"
)
OUTPUT = "assets/icons/splash_icon.png"

PROMPT = (
    "Generate a premium, modern app icon for an AI assistant app called "
    "'Mobile Assistant'. The icon should be:\n"
    "- Rounded square app icon shape\n"
    "- Deep dark navy-black background (#0E0F12)\n"
    "- A friendly, minimal assistant orb/core in desaturated teal (#2DD4BF) "
    "at the center with a soft inner glow\n"
    "- Subtle sparkle/particle accents around the orb\n"
    "- Clean, minimal, flat design — high contrast on dark background\n"
    "- Professional quality, suitable as a mobile app launcher icon\n"
    "- NO text, NO letters, NO words anywhere in the icon\n"
    "- Square composition, fill the entire frame\n"
    "- Subtle depth with soft shadows, not 3D\n"
)


def generate(key: str) -> None:
    payload = json.dumps({
        "contents": [{"parts": [{"text": PROMPT}]}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "temperature": 0.9,
        },
    }).encode()

    req = urllib.request.Request(
        f"{API_URL}?key={key}",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    print("Calling Gemini image generation …")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err = e.read().decode() if e.fp else str(e)
        print(f"API error {e.code}: {err}", file=sys.stderr)
        sys.exit(1)

    # Extract image data from response
    for part in body.get("candidates", [{}])[0] \
                    .get("content", {}) \
                    .get("parts", []):
        if "inlineData" in part:
            img_b64 = part["inlineData"]["data"]
            img_bytes = base64.b64decode(img_b64)
            with open(OUTPUT, "wb") as f:
                f.write(img_bytes)
            print(f"Saved icon → {OUTPUT}  ({len(img_bytes):,} bytes)")
            return

    # No image found — print response for debugging
    print("No image in response. Full body:\n", json.dumps(body, indent=2))
    sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/gen_splash_icon.py <GEMINI_API_KEY>",
              file=sys.stderr)
        sys.exit(1)
    generate(sys.argv[1])
