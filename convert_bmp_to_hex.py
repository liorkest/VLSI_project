import argparse
from PIL import Image

def bmp_to_hex(input_bmp, output_hex):
    """
    Converts a BMP image to a HEX file with RGB values in hexadecimal format.

    Args:
        input_bmp (str): Path to the input BMP image.
        output_hex (str): Path to the output HEX file.
    """
    # Open the BMP image
    img = Image.open(input_bmp)
    
    # Ensure the image is in RGB mode
    img = img.convert("RGB")
    
    # Get the pixel data
    pixels = list(img.getdata())
    print("Number of pixels: " + str(len(pixels)))

    width, height = img.size
    
    # Open the output hex file
    with open(output_hex, 'w') as hex_file:
        # Iterate over all pixels in the image
        for y in range(height):
            for x in range(width):
                r, g, b = pixels[y * width + x]
                # Write RGB values as hexadecimal
                hex_file.write("{:02X}{:02X}{:02X}\n".format(r, g, b))
    print("Hex data written to: " + output_hex)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert a BMP image to a HEX file with RGB values.")
    parser.add_argument("input_bmp", type=str, help="Path to the input BMP file.")
    parser.add_argument("output_hex", type=str, help="Path to save the output HEX file.")

    args = parser.parse_args()

    bmp_to_hex(args.input_bmp, args.output_hex)

