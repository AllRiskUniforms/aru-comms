"""Draws Plato's mouse pointers and writes them next to this file:

  halligan.cur  the normal pointer: a Halligan bar (adz and pick at the head, long
                shaft, fork at the far end)
  fire-axe.cur  over links, in place of the hand: a fire axe (red head with a steel
                blade edge and a pick, wooden handle with a black grip)

Each tool is built from simple shapes, turned so its head sits top-left and the shaft
trails down-right like the normal arrow, with a black outline so it shows on any
background. Each size is drawn at SUPERSAMPLE times and averaged down, so even the tiny
32 px versions have smooth edges. The click point (hotspot) is the top of the head.
Each .cur holds 32, 48 and 64 px versions for 100%, 150% and 200% display scaling.

Re-run after editing (plain Python 3, nothing to install):  python make-cursors.py
"""
import math
import os
import struct

SIZES = (32, 48, 64)
ANGLE = math.radians(-45)  # shaft pointing down-right
SUPERSAMPLE = 3

BLACK = (0, 0, 0)
RED = (205, 25, 25)
STEEL = (220, 225, 230)
DARK_STEEL = (150, 156, 164)
WOOD = (200, 150, 75)
GRIP = (45, 45, 45)


# Shapes, in each tool's own units: head centre at the origin, shaft along +y.

def axe_color(x, y):
    if abs(x) <= 1.5 and 2 <= y <= 18:
        return GRIP if y >= 14 else WOOD
    if abs(x) <= 2.4 and abs(y) <= 3.4:
        return RED
    if x < -2.4:  # blade, widening to its cutting edge
        t = (-x - 2.4) / 6.0
        if t <= 1 and abs(y) <= 2.8 + 2.8 * t:
            return STEEL if t > 0.72 else RED
    if x > 2.4:  # pick on the back, tapering to a point
        t = (x - 2.4) / 7.0
        if t <= 1 and abs(y) <= 2.4 * (1 - t):
            return RED
    return None


def halligan_color(x, y):
    if abs(x) <= 1.8 and abs(y) <= 2.0:
        return STEEL
    if x < -1.8:  # adz: a flat blade, flaring a little toward its edge
        t = (-x - 1.8) / 5.5
        if t <= 1 and -1.4 - 1.0 * t <= y <= 1.4:
            return STEEL
    if x > 1.8:  # pick, tapering to a point
        t = (x - 1.8) / 6.0
        if t <= 1 and abs(y) <= 1.6 * (1 - t):
            return STEEL
    if abs(x) <= 1.3 and 2.0 <= y <= 20:  # shaft
        return DARK_STEEL
    if 20 <= y <= 25:  # fork: two tines spreading apart
        spread = (y - 20) * 0.3
        if 0.5 + spread <= abs(x) <= 2.0 + spread:
            return STEEL
    return None


# name: (shape, size on the 32 px grid, click point in the tool's own units)
POINTERS = {
    'halligan.cur': (halligan_color, 0.38, (0, -2.0)),
    'fire-axe.cur': (axe_color, 0.31, (0, -3.4)),
}


def to_grid(x, y, scale):
    """Tool units -> 32 px grid units, before placing the head."""
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    return (x * c - y * s) * scale, (x * s + y * c) * scale


def placement(shape, scale):
    """Where the head goes so the whole tool sits 1 px in from the top-left (room for the outline)."""
    points = [to_grid(x / 4, y / 4, scale) for x in range(-48, 49) for y in range(-32, 121) if shape(x / 4, y / 4)]
    return 1.5 - min(p[0] for p in points), 1.5 - min(p[1] for p in points)


def render(shape, scale, size):
    """Rows of (r, g, b, alpha) or None (transparent), size x size pixels.

    Drawn at SUPERSAMPLE times the size with an outline SUPERSAMPLE pixels thick (1 px
    once shrunk), then each block of pixels is averaged into one.
    """
    ss = SUPERSAMPLE
    n = size * ss
    k = n / 32
    head = placement(shape, scale)
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    big = []
    for py in range(n):
        row = []
        for px in range(n):
            gx = ((px + 0.5) / k - head[0]) / scale
            gy = ((py + 0.5) / k - head[1]) / scale
            row.append(shape(gx * c + gy * s, -gx * s + gy * c))  # rotate back into tool units
        big.append(row)
    outlined = [row[:] for row in big]
    for py in range(n):
        for px in range(n):
            if big[py][px] is None and any(
                0 <= py + dy < n and 0 <= px + dx < n and big[py + dy][px + dx]
                for dy in range(-ss, ss + 1) for dx in range(-ss, ss + 1)
            ):
                outlined[py][px] = BLACK
    pixels = []
    for y in range(size):
        row = []
        for x in range(size):
            solid = [outlined[y * ss + dy][x * ss + dx] for dy in range(ss) for dx in range(ss)]
            solid = [p for p in solid if p]
            if not solid:
                row.append(None)
                continue
            rgb = [sum(p[i] for p in solid) // len(solid) for i in range(3)]
            row.append((*rgb, round(255 * len(solid) / ss ** 2)))
        pixels.append(row)
    return pixels


def hotspot(shape, scale, point, size):
    hx, hy = to_grid(*point, scale)
    head = placement(shape, scale)
    k = size / 32
    return int((hx + head[0]) * k), int((hy + head[1]) * k)


def cur_image(pixels, size):
    """One 32-bit BMP cursor image: header, BGRA rows bottom-up, then the 1-bit AND mask."""
    color = bytearray()
    mask = bytearray()
    mask_row = ((size + 31) // 32) * 4
    for row in reversed(pixels):
        bits = bytearray(mask_row)
        for x, p in enumerate(row):
            color += bytes((p[2], p[1], p[0], p[3])) if p else bytes(4)
            if not p:
                bits[x // 8] |= 0x80 >> (x % 8)
        mask += bits
    header = struct.pack('<IiiHHIIiiII', 40, size, size * 2, 1, 32, 0, len(color) + len(mask), 0, 0, 0, 0)
    return header + color + mask


def write_cur(path, shape, scale, point):
    images = [cur_image(render(shape, scale, n), n) for n in SIZES]
    out = bytearray(struct.pack('<HHH', 0, 2, len(SIZES)))
    offset = 6 + 16 * len(SIZES)
    for n, img in zip(SIZES, images):
        hx, hy = hotspot(shape, scale, point, n)
        out += struct.pack('<BBBBHHII', n % 256, n % 256, 0, 0, hx, hy, len(img), offset)
        offset += len(img)
    for img in images:
        out += img
    with open(path, 'wb') as f:
        f.write(out)


if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    for name, (shape, scale, point) in POINTERS.items():
        write_cur(os.path.join(here, name), shape, scale, point)
        print('wrote', name, 'hotspot at 32 px:', hotspot(shape, scale, point, 32))
