import argparse
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
    print("Image saved as "+output_bmp)


def main():
    # Set up the argument parser
    parser = argparse.ArgumentParser(description="Convert a hex file to a BMP image.")
    
    # Define the arguments (input hex file, output BMP file, width, height)
    parser.add_argument("input_hex", help="Input hex file with pixel data.")
    parser.add_argument("output_bmp", help="Output BMP file name.")
    parser.add_argument("width", type=int, help="Width of the image.")
    parser.add_argument("height", type=int, help="Height of the image.")
    
    # Parse the arguments
    args = parser.parse_args()

    # Call the hex_to_bmp function with the provided arguments
    hex_to_bmp(args.input_hex, args.output_bmp, args.width, args.height)


if __name__ == "__main__":
    main()

