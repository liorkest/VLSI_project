from PIL import Image

def hex_to_bmp(input_hex, output_bmp, width, height):
    # Open the hex file for reading
    with open(input_hex, 'r') as hex_file:
        # Read all the lines (each line represents one pixel in hex)
        hex_data = hex_file.readlines()
    
    # Prepare a list to store RGB tuples
    pixels = []

    # Iterate over each line and convert the hex values back to RGB tuples
    for line in hex_data:
        # Remove any extra whitespace or newline characters
        line = line.strip()
        
        # Extract the RGB components (2 hex digits for each color)
        r = int(line[0:2], 16)
        g = int(line[2:4], 16)
        b = int(line[4:6], 16)
        
        # Append the RGB tuple to the pixels list
        pixels.append((r, g, b))

    # Create a new image with the specified width and height
    img = Image.new('RGB', (width, height))
    
    # Put the pixels back into the image
    img.putdata(pixels)
    
    # Save the image as a BMP file
    img.save(output_bmp)
    print("Image saved as " + output_bmp)


# Assuming the hex file is 'output.hex' and the image dimensions are 480x360
hex_to_bmp('output_wiener_reordered.hex', 'output_wiener.bmp', 480, 360)


