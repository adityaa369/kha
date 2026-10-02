from PIL import Image

# Open images
logo = Image.open('assets/images/splash_logo.png').convert("RGBA")
title = Image.open('assets/images/splash_title.png').convert("RGBA")
subtitle = Image.open('assets/images/splash_subtitle.png').convert("RGBA")

# Create 1152x1152 transparent canvas
canvas = Image.new('RGBA', (1152, 1152), (0, 0, 0, 0))

# Y offset to center roughly
logo_y = 421
canvas.paste(logo, ((1152 - logo.width) // 2, logo_y), logo)

title_y = logo_y + logo.height + 40
canvas.paste(title, ((1152 - title.width) // 2, title_y), title)

sub_y = title_y + title.height + 20
canvas.paste(subtitle, ((1152 - subtitle.width) // 2, sub_y), subtitle)

# Save
canvas.save('assets/images/android12_splash.png')
print('Generated assets/images/android12_splash.png')
