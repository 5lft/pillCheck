"""App Store 스크린샷 합성기 (6.9인치, 1320x2868).

    python3 tool/make_store_screenshots.py <원본 스크린샷 폴더>

원본 폴더에는 iPhone 17 Pro Max 시뮬레이터에서 찍은 today.png, list.png,
history.png, form.png, today_dark.png가 있어야 한다.
결과는 store/screenshots/ 에 01_today.png ... 순서로 저장된다.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store/screenshots"
W, H = 1320, 2868

ACCENT = (0x3D, 0x6B, 0xFF)
VIOLET = (0x7B, 0x5C, 0xFF)
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
BOLD, MEDIUM = 6, 2

SHOTS = [
    ("today", "약 먹을 시간,\n잊지 않게 알려드려요", "복용 시간에 맞춰 알림이 와요"),
    ("list", "먹고 있는 약을\n한눈에", "시간·요일·메모까지 깔끔하게"),
    ("history", "7일 복용률로\n꾸준함을 확인해요", "놓친 날도 바로 체크할 수 있어요"),
    ("form", "시간과 요일만 고르면\n등록 끝", "하루 여러 번, 요일별 복용도 OK"),
    ("today_dark", "밤에도 눈부시지 않게,\n다크 모드", "기기 설정을 따라 자동으로 바뀌어요"),
]


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def background(dark=False):
    top, bottom = (ACCENT, lerp(ACCENT, VIOLET, 0.6))
    if dark:
        top, bottom = (0x16, 0x18, 0x24), (0x24, 0x22, 0x3A)
    strip = Image.new("RGB", (1, 256))
    for y in range(256):
        strip.putpixel((0, y), lerp(top, bottom, y / 255))
    return strip.resize((W, H), Image.BICUBIC)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.width - 1, img.height - 1], radius=radius, fill=255
    )
    return mask


def compose(raw: Path, key: str, title: str, subtitle: str) -> Image.Image:
    dark = key.endswith("dark")
    canvas = background(dark)
    draw = ImageDraw.Draw(canvas)

    title_font = ImageFont.truetype(FONT, 104, index=BOLD)
    sub_font = ImageFont.truetype(FONT, 48, index=MEDIUM)

    y = 190
    for line in title.split("\n"):
        w = draw.textlength(line, font=title_font)
        draw.text(((W - w) / 2, y), line, font=title_font, fill="white")
        y += 132
    y += 18
    w = draw.textlength(subtitle, font=sub_font)
    draw.text(((W - w) / 2, y), subtitle, font=sub_font, fill=(255, 255, 255, 210))

    shot = Image.open(raw / f"{key}.png").convert("RGB")
    scale = 0.69
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    x0, y0 = (W - sw) // 2, 790

    # 기기 테두리 + 그림자
    bezel = 22
    frame_box = [x0 - bezel, y0 - bezel, x0 + sw + bezel, y0 + sh + bezel]
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        [frame_box[0], frame_box[1] + 30, frame_box[2], frame_box[3] + 30],
        radius=120,
        fill=110,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(50))
    canvas.paste((10, 14, 40), mask=shadow)
    ImageDraw.Draw(canvas).rounded_rectangle(frame_box, radius=118, fill=(18, 18, 22))
    canvas.paste(shot, (x0, y0), rounded(shot, 98))
    return canvas


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    raw = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (key, title, subtitle) in enumerate(SHOTS, start=1):
        out = OUT / f"{i:02d}_{key}.png"
        compose(raw, key, title, subtitle).save(out)
        print(f"  {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
