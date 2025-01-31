import argparse
import numpy as np
from PIL import Image

def color_image_similarity(image1_path, image2_path, diff_output_path=None):
    # Load images using PIL
    img1 = Image.open(image1_path).convert("RGB")
    img2 = Image.open(image2_path).convert("RGB")

    # Ensure images have the same size
    if img1.size != img2.size:
        print("Error: Images must have the same dimensions.")
        return None

    # Convert images to NumPy arrays
    img1 = np.array(img1, dtype=np.int16)  # Use int16 to prevent overflow
    img2 = np.array(img2, dtype=np.int16)

    # Compute absolute pixel differences
    diff = np.abs(img1 - img2)
    print("The minimal difference is: " + str(diff.min()))
    print("The maximal difference is: " + str(diff.max()))

    # Convert RGB difference to grayscale (perceived luminance method)
    grayscale_diff = (0.2989 * diff[:, :, 0] + 0.5870 * diff[:, :, 1] + 0.1140 * diff[:, :, 2]).astype(np.uint8)

    # Save grayscale difference image if an output path is provided
    if diff_output_path:
        Image.fromarray(grayscale_diff).save(diff_output_path)
        print("Difference image saved at: " + diff_output_path)
  
    # Compute mean difference per channel
    mean_diff = np.mean(diff)
    
    # Compute a similarity score (100% means identical)
    similarity = 100 - (mean_diff / 255 * 100)

    return similarity

def main():
    parser = argparse.ArgumentParser(description="Compare two color images and calculate a similarity score.")
    parser.add_argument("image1", help="Path to the first image.")
    parser.add_argument("image2", help="Path to the second image.")
    parser.add_argument("--diff_output", help="Path to save the grayscale difference image.", default="difference.png")
    
    args = parser.parse_args()

    similarity_score = color_image_similarity(args.image1, args.image2, args.diff_output)

    if similarity_score is not None:
    	print("Similarity Score: {:.2f}%".format(similarity_score))

if __name__ == "__main__":
    main()

## python image_compare.py image1.bmp image2.bmp --diff_output diff_result.png

