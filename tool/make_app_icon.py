"""약챙김 앱 아이콘 생성기.

    python3 tool/make_app_icon.py

1024x1024 원본을 그린 뒤 ios/Runner/Assets.xcassets/AppIcon.appiconset의
Contents.json에 적힌 모든 사이즈로 내보낸다. App Store 규정에 맞게 알파 채널 없이
정사각형 전체를 채운다(모서리 라운드는 iOS가 적용).
색은 lib/app/theme/app_theme.dart의 AppPalette.light.accent와 맞춘다.
"""

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

SIZE = 1024
SS = 4  # 슈퍼샘플링 배율 (안티앨리어싱)
S = SIZE * SS

ACCENT = (0x3D, 0x6B, 0xFF)
VIOLET = (0x7B, 0x5C, 0xFF)
WHITE = (255, 255, 255)


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient_background():
    """좌상단 accent → 우하단 보라 대각선 그라데이션 (오늘 화면 진행 카드와 같은 톤)"""
    end = lerp(ACCENT, VIOLET, 0.55)
    small = Image.new("RGB", (256, 256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            t = (x + y) / (2 * 255)
            px[x, y] = lerp(ACCENT, end, t)
    return small.resize((S, S), Image.BICUBIC)


def rotated_capsule_mask(cx, cy, length, width, angle_deg):
    """중심 (cx, cy), 길이 length, 두께 width인 캡슐을 angle만큼 돌린 마스크 2장(왼쪽/오른쪽 반쪽)"""
    w, h = int(length), int(width)
    left = Image.new("L", (w, h), 0)
    right = Image.new("L", (w, h), 0)
    r = h // 2
    dl = ImageDraw.Draw(left)
    dr = ImageDraw.Draw(right)
    gap = int(h * 0.06)  # 두 반쪽 사이 이음매
    dl.rounded_rectangle([0, 0, w // 2 - gap // 2, h - 1], radius=r, fill=255)
    dl.rectangle([r, 0, w // 2 - gap // 2, h - 1], fill=255)
    dr.rounded_rectangle([w // 2 + gap // 2, 0, w - 1, h - 1], radius=r, fill=255)
    dr.rectangle([w // 2 + gap // 2, 0, w - 1 - r, h - 1], fill=255)

    out = []
    for m in (left, right):
        m = m.rotate(angle_deg, resample=Image.BICUBIC, expand=True)
        canvas = Image.new("L", (S, S), 0)
        canvas.paste(m, (int(cx - m.width / 2), int(cy - m.height / 2)))
        out.append(canvas)
    return out


def draw_icon():
    img = gradient_background()

    cx, cy = S * 0.47, S * 0.47
    length, width = S * 0.62, S * 0.25
    left, right = rotated_capsule_mask(cx, cy, length, width, 45)

    # 부드러운 그림자
    shadow_mask = Image.new("L", (S, S), 0)
    shadow_mask.paste(255, mask=left)
    shadow_mask.paste(255, mask=right)
    shadow_mask = shadow_mask.transform(
        (S, S), Image.AFFINE, (1, 0, 0, 0, 1, -int(S * 0.018))
    ).filter(ImageFilter.GaussianBlur(S * 0.02))
    shadow = Image.new("RGB", (S, S), lerp(ACCENT, (0, 0, 40), 0.45))
    img.paste(shadow, mask=shadow_mask.point(lambda v: int(v * 0.35)))

    # 캡슐: 한쪽은 흰색, 한쪽은 반투명 흰색
    img.paste(Image.new("RGB", (S, S), WHITE), mask=left)
    img.paste(
        Image.new("RGB", (S, S), lerp(WHITE, ACCENT, 0.28)),
        mask=right,
    )

    # 체크 배지 (우하단)
    bx, by, br = S * 0.70, S * 0.70, S * 0.165
    badge = Image.new("L", (S, S), 0)
    ImageDraw.Draw(badge).ellipse([bx - br, by - br, bx + br, by + br], fill=255)
    ring = Image.new("L", (S, S), 0)
    rr = br + S * 0.028
    ImageDraw.Draw(ring).ellipse([bx - rr, by - rr, bx + rr, by + rr], fill=255)
    img.paste(Image.new("RGB", (S, S), lerp(ACCENT, VIOLET, 0.4)), mask=ring)
    img.paste(Image.new("RGB", (S, S), WHITE), mask=badge)

    d = ImageDraw.Draw(img)
    stroke = int(S * 0.034)
    p1 = (bx - br * 0.46, by + br * 0.02)
    p2 = (bx - br * 0.10, by + br * 0.36)
    p3 = (bx + br * 0.50, by - br * 0.32)
    d.line([p1, p2, p3], fill=ACCENT, width=stroke, joint="curve")
    for p in (p1, p3):  # 둥근 끝
        d.ellipse(
            [p[0] - stroke / 2, p[1] - stroke / 2, p[0] + stroke / 2, p[1] + stroke / 2],
            fill=ACCENT,
        )

    return img.resize((SIZE, SIZE), Image.LANCZOS)


def export(master):
    contents = json.loads((ICONSET / "Contents.json").read_text())
    written = set()
    for entry in contents["images"]:
        name = entry.get("filename")
        if not name or name in written:
            continue
        base = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        px = round(base * scale)
        master.resize((px, px), Image.LANCZOS).convert("RGB").save(ICONSET / name)
        written.add(name)
        print(f"  {name:32} {px}x{px}")


if __name__ == "__main__":
    icon = draw_icon()
    out = ROOT / "tool/app_icon_1024.png"
    icon.save(out)
    print(f"master → {out.relative_to(ROOT)}")
    export(icon)
