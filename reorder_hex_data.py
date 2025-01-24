import argparse

def rearrange_pixels(input_file, output_file, width, block_size=8):
    """
    Rearranges pixels from blocks to line-by-line order.
    
    Args:
        input_file (str): Path to the input hex file.
        output_file (str): Path to save the rearranged hex file.
        width (int): Image width in pixels.
        block_size (int): Block size (default is 8x8).
    """
    # Read pixels from the input file
    with open(input_file, "r") as f:
        pixels = [line.strip() for line in f]

    # Calculate the number of blocks in a row
    blocks_per_row = width // block_size

    # Rearrange pixels
    rearranged = []
    rows_per_block = len(pixels) // (block_size ** 2 * blocks_per_row)
    for row in range(rows_per_block * block_size):
        for block in range(blocks_per_row):
            start = (block + row // block_size * blocks_per_row) * block_size ** 2 + (row % block_size) * block_size
            rearranged.extend(pixels[start:start + block_size])

    # Write the rearranged pixels to the output file
    with open(output_file, "w") as f:
        f.write("\n".join(rearranged))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rearrange pixels from blocks to line-by-line order in a hex file.")
    parser.add_argument("input_file", type=str, help="Path to the input hex file.")
    parser.add_argument("output_file", type=str, help="Path to save the rearranged hex file.")
    parser.add_argument("width", type=int, help="Image width in pixels.")

    args = parser.parse_args()

    rearrange_pixels(args.input_file, args.output_file, args.width)

