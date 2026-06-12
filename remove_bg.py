from PIL import Image

def remove_background(image_path, output_path, target_color, tolerance=15):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # Check if pixel is close to target_color
        if (abs(item[0] - target_color[0]) <= tolerance and
            abs(item[1] - target_color[1]) <= tolerance and
            abs(item[2] - target_color[2]) <= tolerance):
            # Change the target color to transparent
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    # #EBF5EC is (235, 245, 236)
    target_bg = (235, 245, 236)
    input_file = "assets/images/hero_3d.png"
    output_file = "assets/images/hero_3d.png"
    
    remove_background(input_file, output_file, target_bg, tolerance=30)
    print("Background removed successfully.")
