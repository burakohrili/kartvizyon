from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "store-assets" / "google-play" / "screenshots"
LOGO = ROOT.parent / "web" / "public" / "icons" / "icon-512.png"

FONT_REGULAR = Path(r"C:\Windows\Fonts\segoeui.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius, fill=255)
    return mask


def make_store_shot(source_name: str, output_name: str, eyebrow: str, title: str, subtitle: str) -> None:
    width, height = 1080, 1920
    canvas = Image.new("RGB", (width, height), "#10152f")
    draw = ImageDraw.Draw(canvas)

    # Subtle product-colored light fields keep the composition dimensional without
    # hiding the real product UI.
    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((-260, -300, 720, 680), fill=(55, 111, 255, 75))
    glow_draw.ellipse((520, 180, 1350, 1040), fill=(255, 195, 17, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), glow)
    draw = ImageDraw.Draw(canvas)

    logo = Image.open(LOGO).convert("RGBA").resize((92, 92), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (78, 78))
    draw.text((190, 88), "KartVizyon", font=font(46, True), fill="#ffffff")
    draw.text((190, 142), "AI saha hafızası", font=font(25), fill="#aeb9db")

    draw.text((78, 245), eyebrow.upper(), font=font(25, True), fill="#ffc719")
    title_font = font(72, True)
    title_lines = []
    words = title.split()
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=title_font) <= 900:
            current = candidate
        else:
            title_lines.append(current)
            current = word
    title_lines.append(current)
    title_y = 300
    for line in title_lines:
        draw.text((78, title_y), line, font=title_font, fill="#ffffff")
        title_y += 82

    draw.text((82, title_y + 20), subtitle, font=font(30), fill="#c7cee4")

    # Device frame uses the actual product screen. Crop the browser-only scrollbar
    # and development badge before placing it inside the frame.
    raw = Image.open(SCREENSHOTS / source_name).convert("RGB")
    raw = raw.crop((0, 0, min(raw.width - 10, 330), min(raw.height, 545)))
    raw_draw = ImageDraw.Draw(raw)
    if source_name.startswith("phone-dashboard"):
        # The embedded browser exposes a scrollbar for the swipeable mobile tab row;
        # keep the tabs while removing that browser chrome from the store image.
        raw_draw.rectangle((14, 134, 316, 165), fill="#191d3e")
    phone_w, phone_h = 820, 1300
    phone_x, phone_y = 130, 610

    shadow = Image.new("RGBA", (phone_w + 120, phone_h + 120), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((60, 45, phone_w + 60, phone_h + 45), 88, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(35))
    canvas.alpha_composite(shadow, (phone_x - 60, phone_y - 45))

    draw.rounded_rectangle((phone_x, phone_y, phone_x + phone_w, phone_y + phone_h), 82, fill="#080b17")
    inset = 22
    screen_size = (phone_w - inset * 2, phone_h - inset * 2)
    screen = raw.resize(screen_size, Image.Resampling.LANCZOS)
    screen.putalpha(rounded_mask(screen_size, 62))
    canvas.alpha_composite(screen, (phone_x + inset, phone_y + inset))

    # Camera island and home indicator complete the device presentation.
    draw.rounded_rectangle((438, phone_y + 35, 642, phone_y + 70), 18, fill="#080b17")
    draw.rounded_rectangle((445, phone_y + phone_h - 38, 635, phone_y + phone_h - 25), 7, fill="#d9dce7")

    canvas.convert("RGB").save(SCREENSHOTS / output_name, quality=94, optimize=True)


make_store_shot(
    "phone-dashboard-360x640.png",
    "01-dashboard-1080x1920.png",
    "Günün saha özeti",
    "Ekibiniz kaldığı yerden devam etsin.",
    "Ziyaret, takip ve fırsatlar tek bakışta.",
)

make_store_shot(
    "phone-debrief-360x640.png",
    "02-ai-debrief-1080x1920.png",
    "Ziyaret sonrası",
    "Notunu bırakın. AI taslağını hazırlasın.",
    "Kurumsal hafızaya yalnız onayladığınız içerik eklenir.",
)
