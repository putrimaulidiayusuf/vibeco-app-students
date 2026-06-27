from PIL import Image, ImageDraw

width = 1080
height = 2400

image = Image.new('RGB', (width, height))
draw = ImageDraw.Draw(image)

# Top color: #06241B (6, 36, 27) -> base emerald color
# Bottom color: #0A3D2D (10, 61, 45) -> a bit lighter emerald
r1, g1, b1 = 6, 36, 27
r2, g2, b2 = 10, 61, 45

for y in range(height):
    r = int(r1 + (r2 - r1) * y / height)
    g = int(g1 + (g2 - g1) * y / height)
    b = int(b1 + (b2 - b1) * y / height)
    draw.line([(0, y), (width, y)], fill=(r, g, b))

image.save('assets/images/splash_gradient_bg.png')
print("Gradient saved!")
