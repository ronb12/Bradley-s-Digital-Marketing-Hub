#!/usr/bin/env python3
"""
Generate a professional app icon for Bradley Digital Marketing Hub
Creates a 1024x1024 PNG icon with brand colors
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import math
except ImportError:
    print("Installing required packages...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw, ImageFont
    import math

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_app_icon(output_path="AppIcon-1024.png"):
    """Create a professional app icon for Bradley Digital Marketing Hub"""
    
    # Brand colors
    hub_blue = hex_to_rgb("#5B8DEF")  # Free tier
    pro_green = hex_to_rgb("#2AA876")  # Pro tier
    agency_purple = hex_to_rgb("#7F52FF")  # Agency tier
    
    # Create 1024x1024 image
    size = 1024
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (blue to purple)
    center_x, center_y = size // 2, size // 2
    
    # Draw radial gradient background
    for i in range(size):
        for j in range(size):
            # Distance from center
            dx = i - center_x
            dy = j - center_y
            distance = math.sqrt(dx*dx + dy*dy)
            max_distance = math.sqrt(center_x*center_x + center_y*center_y)
            
            # Interpolate between blue and purple
            ratio = min(distance / (max_distance * 0.8), 1.0)
            r = int(hub_blue[0] * (1 - ratio) + agency_purple[0] * ratio)
            g = int(hub_blue[1] * (1 - ratio) + agency_purple[1] * ratio)
            b = int(hub_blue[2] * (1 - ratio) + agency_purple[2] * ratio)
            
            img.putpixel((i, j), (r, g, b))
    
    # Draw hub design - multiple connected nodes
    node_radius = 80
    nodes = []
    
    # Center hub node (larger)
    nodes.append((center_x, center_y, 120, hub_blue))
    
    # Surrounding nodes representing different features
    num_nodes = 5
    for i in range(num_nodes):
        angle = (2 * math.pi * i) / num_nodes
        x = center_x + int(280 * math.cos(angle))
        y = center_y + int(280 * math.sin(angle))
        # Alternate colors
        color = pro_green if i % 2 == 0 else hub_blue
        nodes.append((x, y, node_radius, color))
    
    # Draw connections between nodes
    for i, (x1, y1, r1, _) in enumerate(nodes):
        for j, (x2, y2, r2, _) in enumerate(nodes[i+1:], i+1):
            if i == 0:  # Connect all to center
                draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 100), width=8)
    
    # Draw nodes
    for x, y, radius, color in nodes:
        # Outer glow
        draw.ellipse([x - radius - 15, y - radius - 15, 
                     x + radius + 15, y + radius + 15], 
                    fill=(*color, 100))
        # Main node
        draw.ellipse([x - radius, y - radius, 
                     x + radius, y + radius], 
                    fill=color, outline=(255, 255, 255), width=6)
        # Inner highlight
        draw.ellipse([x - radius + 20, y - radius + 20, 
                     x + radius - 20, y + radius - 20], 
                    fill=(255, 255, 255, 150))
    
    # Add "B" monogram in center
    try:
        # Try to use a system font, fallback to default if not available
        font_size = 180
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
            except:
                font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Draw "B" letter
    text = "B"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = center_x - text_width // 2
    text_y = center_y - text_height // 2
    
    # Text shadow
    draw.text((text_x + 4, text_y + 4), text, font=font, fill=(0, 0, 0, 100))
    # Main text
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255))
    
    # Save the icon
    img.save(output_path, 'PNG', quality=95)
    print(f"✅ App icon created successfully: {output_path}")
    print(f"   Size: 1024x1024 pixels")
    print(f"   Format: PNG")
    
    return output_path

if __name__ == "__main__":
    output_file = "Bradley Digital Marketing Hub/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    create_app_icon(output_file)
    print("\n🎨 Icon design features:")
    print("   - Hub network design (represents central platform)")
    print("   - Blue to purple gradient background")
    print("   - Connected nodes (represents features/modules)")
    print("   - 'B' monogram for Bradley")
    print("   - Modern, professional appearance")

