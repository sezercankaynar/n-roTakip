"""NöroCep uygulama simgesini üretir.

Bordo zemin üzerinde krem renkli beyin silueti ve içinden geçen nabız
çizgisi. Android'in eski (kare) ve uyarlanabilir (adaptive) simgeleri ile
uygulama içinde kullanılan logo.png dosyasını yazar.

Kullanım: python3 tool/gen_icon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"

BORDO_TOP = (163, 50, 74)
BORDO_BOTTOM = (110, 26, 42)
BORDO = (139, 38, 53)
CREAM = (255, 244, 232)

# Yandan beyin silueti (ön taraf solda): (dx, dy, r) sembol boyutuna oranla.
LOBES = [
    (-0.21, -0.03, 0.21),  # frontal
    (0.0, -0.13, 0.22),  # üst
    (0.19, -0.07, 0.20),  # parietal-oksipital
    (-0.05, 0.09, 0.20),  # temporal
    (0.20, 0.07, 0.15),  # oksipital alt
]
CEREBELLUM = (0.19, 0.21, 0.10)

# Kıvrımlar (sulkuslar): (merkez dx, dy, yarıçap, başlangıç°, bitiş°).
SULCI = [
    (-0.17, -0.12, 0.10, 200, 300),
    (0.02, -0.22, 0.10, 210, 330),
    (0.19, -0.13, 0.09, 230, 340),
]

PULSE = [
    (-0.36, 0.04),
    (-0.15, 0.04),
    (-0.10, -0.04),
    (-0.04, 0.15),
    (0.03, -0.16),
    (0.09, 0.08),
    (0.13, 0.04),
    (0.36, 0.04),
]


def draw_symbol(img: Image.Image, cx: float, cy: float, s: float) -> None:
    d = ImageDraw.Draw(img)

    def circle(dx: float, dy: float, r: float, fill) -> None:
        x, y, rr = cx + dx * s, cy + dy * s, r * s
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=fill)

    # Beyin sapı, beyincik, sonra lobları.
    d.rounded_rectangle(
        (cx + 0.02 * s, cy + 0.12 * s, cx + 0.12 * s, cy + 0.36 * s),
        radius=int(0.04 * s),
        fill=CREAM,
    )
    circle(*CEREBELLUM, CREAM)
    for lobe in LOBES:
        circle(*lobe, CREAM)

    thin = max(2, int(0.022 * s))
    for dx, dy, r, a0, a1 in SULCI:
        x, y, rr = cx + dx * s, cy + dy * s, r * s
        d.arc((x - rr, y - rr, x + rr, y + rr), a0, a1, fill=BORDO, width=thin)
    # Beyincik çizgileri.
    bx, by, br = CEREBELLUM
    for k in (-0.03, 0.02):
        x, y, rr = cx + bx * s, cy + (by + k) * s, br * 0.75 * s
        d.arc((x - rr, y - rr * 0.5, x + rr, y + rr * 0.5), 20, 160,
              fill=BORDO, width=max(1, thin // 2 + 1))

    pts = [(cx + x * s, cy + y * s) for x, y in PULSE]
    d.line(pts, fill=BORDO, width=max(3, int(0.05 * s)), joint="curve")
    for p in (pts[0], pts[-1]):
        rr = 0.025 * s
        d.ellipse((p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr), fill=BORDO)


def gradient(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        c = tuple(
            int(BORDO_TOP[i] + (BORDO_BOTTOM[i] - BORDO_TOP[i]) * t)
            for i in range(3)
        )
        d.line([(0, y), (size, y)], fill=c + (255,))
    return img


def legacy(size: int) -> Image.Image:
    """Köşeleri yuvarlatılmış kare simge (4 kat büyük çizip küçültür)."""
    big = size * 4
    bg = gradient(big)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=int(big * 0.22), fill=255
    )
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    draw_symbol(out, big / 2, big / 2, big * 0.78)
    return out.resize((size, size), Image.LANCZOS)


def foreground(size: int) -> Image.Image:
    """Uyarlanabilir simge ön yüzü: sembol güvenli alanın içinde."""
    big = size * 4
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw_symbol(out, big / 2, big / 2, big * 0.6)
    return out.resize((size, size), Image.LANCZOS)


def main() -> None:
    legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144,
                    "xxxhdpi": 192}
    for name, px in legacy_sizes.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy(px).save(folder / "ic_launcher.png")
        foreground(int(px * 108 / 48)).save(
            folder / "ic_launcher_foreground.png"
        )

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android='
        '"http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n'
    )
    values = RES / "values"
    (values / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <color name="ic_launcher_background">#8B2635</color>\n'
        '</resources>\n'
    )

    images = ROOT / "assets/images"
    images.mkdir(parents=True, exist_ok=True)
    legacy(256).save(images / "logo.png")



if __name__ == "__main__":
    main()
