"""Draws Plato's fire-axe mouse pointer and writes fire-axe.cur next to this file.

Built from simple shapes: a red axe head (steel blade edge, pick on the back) on a wooden
handle with a black grip, turned so the head sits top-left and the handle trails
down-right like the normal arrow, with a black outline so it shows on any background.
Each size is drawn at SUPERSAMPLE times and averaged down, so even the tiny 32 px axe
has smooth edges. The click point (hotspot) is the top of the head. The .cur holds 32,
48 and 64 px versions for 100%, 150% and 200% display scaling.

Re-run after editing (plain Python 3, nothing to install):  python make-cursors.py
"""
import math
import os
import struct

SIZES = (32, 48, 64)
SCALE = 0.31     # axe size on the 32 px grid; the default Windows arrow is about 12x19 px
ANGLE = math.radians(-45)  # handle pointing down-right
SUPERSAMPLE = 3

BLACK = (0, 0, 0)
RED = (205, 25, 25)
STEEL = (220, 225, 230)
WOOD = (200, 150, 75)
GRIP = (45, 45, 45)


def axe_color(x, y):
    """Colour at a point in the axe's own units: head centre at the origin, handle along +y."""
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


def to_grid(x, y):
    """Axe units -> 32 px grid units, before placing the head."""
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    return (x * c - y * s) * SCALE, (x * s + y * c) * SCALE


# Place the head so the whole axe sits 1 px in from the top-left corner (room for the outline).
_points = [to_grid(x / 4, y / 4) for x in range(-40, 41) for y in range(-24, 76) if axe_color(x / 4, y / 4)]
HEAD = (1.5 - min(p[0] for p in _points), 1.5 - min(p[1] for p in _points))


def render(size):
    """Rows of (r, g, b, alpha) or None (transparent), size x size pixels.

    Drawn at SUPERSAMPLE times the size with an outline SUPERSAMPLE pixels thick (1 px
    once shrunk), then each block of pixels is averaged into one.
    """
    ss = SUPERSAMPLE
    n = size * ss
    k = n / 32
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    big = []
    for py in range(n):
        row = []
        for px in range(n):
            gx = ((px + 0.5) / k - HEAD[0]) / SCALE
            gy = ((py + 0.5) / k - HEAD[1]) / SCALE
            row.append(axe_color(gx * c + gy * s, -gx * s + gy * c))  # rotate back into axe units
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


def hotspot(size):
    hx, hy = to_grid(0, -3.4)  # top of the head
    k = size / 32
    return int((hx + HEAD[0]) * k), int((hy + HEAD[1]) * k)


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


def write_cur(path):
    images = [cur_image(render(n), n) for n in SIZES]
    out = bytearray(struct.pack('<HHH', 0, 2, len(SIZES)))
    offset = 6 + 16 * len(SIZES)
    for n, img in zip(SIZES, images):
        hx, hy = hotspot(n)
        out += struct.pack('<BBBBHHII', n % 256, n % 256, 0, 0, hx, hy, len(img), offset)
        offset += len(img)
    for img in images:
        out += img
    with open(path, 'wb') as f:
        f.write(out)


if __name__ == '__main__':
    target = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fire-axe.cur')
    write_cur(target)
    print('wrote', target, 'hotspot at 32 px:', hotspot(32))
