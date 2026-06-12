from PIL import Image
import sys

def magic_wand_remove_bg(image_path, output_path, tolerance=40):
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    # Get the background color from the top-left corner
    bg_color = pixels[0, 0]

    # BFS to find all connected background pixels
    visited = set()
    queue = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    
    for start_node in queue:
        if start_node not in visited:
            q = [start_node]
            while q:
                x, y = q.pop(0)
                if (x, y) in visited:
                    continue
                
                visited.add((x, y))
                
                # Check color distance
                current_color = pixels[x, y]
                dist = sum(abs(current_color[i] - bg_color[i]) for i in range(3))
                
                if dist <= tolerance:
                    # Make it transparent
                    pixels[x, y] = (255, 255, 255, 0)
                    
                    # Add neighbors
                    if x > 0: q.append((x - 1, y))
                    if x < width - 1: q.append((x + 1, y))
                    if y > 0: q.append((x, y - 1))
                    if y < height - 1: q.append((x, y + 1))

    img.save(output_path, "PNG")

if __name__ == "__main__":
    try:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        magic_wand_remove_bg(input_file, output_file, tolerance=60)
        print("Magic wand background removal successful.")
    except Exception as e:
        print(f"Error: {e}")
