from PIL import Image

def bmp_to_hex(input_bmp, output_hex):
    # Open the BMP image
    img = Image.open(input_bmp)
    
    # Ensure the image is in RGB mode
    img = img.convert("RGB")
    
    # Get the pixel data
    pixels = list(img.getdata())
    print("number of pixels: " + str(len(pixels)))

    width, height = img.size
    
    # Open the output hex file
    with open(output_hex, 'w') as hex_file:
        # Iterate over all pixels in the image
        for y in range(height):
            for x in range(width):
                r, g, b = pixels[y * width + x]
                # Use .format() for Python 2.x compatibility
                hex_file.write("{:02X}{:02X}{:02X}\n".format(r, g, b))
    print("Hex data written to: "+ output_hex)

# Example usage:
bmp_to_hex('hedgehog_noisy.bmp', 'hedgehog_noisy.hex')

