"""Generates a simple flat app-icon PNG for HabitForge: an emerald gradient
square with a white checkmark, matching HabitForgeColors.primary/primaryDark.
Pure stdlib (struct + zlib) — no image libraries available in this environment.

Run once with `python tool/generate_app_icon.py`, then `flutter pub run
flutter_launcher_icons` to regenerate the platform icon sets from it.
"""
import struct
import zlib

SIZE = 1024
TOP_LEFT = (0x10, 0xB9, 0x81)      # HabitForgeColors.primary      #10B981
BOTTOM_RIGHT = (0x05, 0x96, 0x69)  # HabitForgeColors.primaryDark  #059669
WHITE = (255, 255, 255)


def lerp(a, b, t):
    return a + (b - a) * t


def gradient_color(x, y):
    t = (x + y) / (2 * (SIZE - 1))
    return tuple(int(round(lerp(TOP_LEFT[i], BOTTOM_RIGHT[i], t))) for i in range(3))


def dist_to_segment(px, py, ax, ay, bx, by):
    abx, aby = bx - ax, by - ay
    apx, apy = px - ax, py - ay
    ab_len_sq = abx * abx + aby * aby
    t = max(0.0, min(1.0, (apx * abx + apy * aby) / ab_len_sq))
    cx, cy = ax + t * abx, ay + t * aby
    dx, dy = px - cx, py - cy
    return (dx * dx + dy * dy) ** 0.5


# Checkmark polyline (short arm + long arm), centered in the canvas.
P1 = (SIZE * 0.30, SIZE * 0.54)
P2 = (SIZE * 0.44, SIZE * 0.68)
P3 = (SIZE * 0.72, SIZE * 0.36)
STROKE = SIZE * 0.075
AA = 1.4  # antialias feather width in pixels


def checkmark_coverage(x, y):
    d1 = dist_to_segment(x, y, *P1, *P2)
    d2 = dist_to_segment(x, y, *P2, *P3)
    d = min(d1, d2)
    if d <= STROKE - AA:
        return 1.0
    if d >= STROKE + AA:
        return 0.0
    return (STROKE + AA - d) / (2 * AA)


def build_image(transparent=False):
    """`transparent=True` renders just the checkmark on a transparent ground,
    shrunk towards the centre so it survives the adaptive-icon safe-zone crop."""
    rows = []
    for y in range(SIZE):
        row = bytearray([0])  # filter byte: None
        for x in range(SIZE):
            if transparent:
                # Sample the checkmark at 70% scale around the centre so the
                # glyph stays inside the launcher's circular/squircle mask.
                cx = cy = SIZE / 2
                sx = cx + (x - cx) / 0.70
                sy = cy + (y - cy) / 0.70
                cov = checkmark_coverage(sx + 0.5, sy + 0.5)
                row += bytes((*WHITE, int(round(255 * cov))))
            else:
                r, g, b = gradient_color(x, y)
                cov = checkmark_coverage(x + 0.5, y + 0.5)
                if cov > 0:
                    r = int(round(lerp(r, WHITE[0], cov)))
                    g = int(round(lerp(g, WHITE[1], cov)))
                    b = int(round(lerp(b, WHITE[2], cov)))
                row += bytes((r, g, b, 255))
        rows.append(bytes(row))
    return b"".join(rows)


def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


def write_png(path, transparent=False):
    raw = build_image(transparent=transparent)
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    idat = zlib.compress(raw, 9)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    import os
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    os.makedirs(out_dir, exist_ok=True)

    icon_path = os.path.join(out_dir, "icon.png")
    write_png(icon_path, transparent=False)
    print(f"Wrote {icon_path} ({SIZE}x{SIZE})")

    fg_path = os.path.join(out_dir, "icon_foreground.png")
    write_png(fg_path, transparent=True)
    print(f"Wrote {fg_path} ({SIZE}x{SIZE}, transparent)")
