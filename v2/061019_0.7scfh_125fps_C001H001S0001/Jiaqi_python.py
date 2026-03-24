import cv2
import numpy as np
import os
from glob import glob
import pandas as pd
from skimage import measure
import matplotlib.pyplot as plt

# -----------------------
# USER SETTINGS
# -----------------------
input_dir = "frames_partial"          # folder with images
background_path = "background.jpg"
output_dir = "output"
csv_file = os.path.join(output_dir, "bubble_data.csv")

# cropping: (y1:y2, x1:x2)
crop = (0, 600, 300, 650)

# frame selection
start_frame = 0
end_frame = None   # None = all frames
step = 1

# -----------------------
os.makedirs(output_dir, exist_ok=True)

# -----------------------
# LOAD BACKGROUND
# -----------------------
bg = cv2.imread(background_path, cv2.IMREAD_GRAYSCALE)
# y1, y2, x1, x2 = crop
# bg = bg[y1:y2, x1:x2]

# invert background
bg_inv = 255 - bg
bg_inv = bg_inv.astype(np.float32)

# slight enhancement (matches MATLAB)
bg_inv[bg_inv > 0] += 50
bg_inv = np.clip(bg_inv, 0, 255)

# -----------------------
# LOAD FRAMES
# -----------------------
image_paths = sorted(glob(os.path.join(input_dir, "*.png")))
if end_frame is None:
    end_frame = len(image_paths)
image_paths = image_paths[start_frame:end_frame:step]

# -----------------------
# HELPERS
def fill_holes(binary):
    h, w = binary.shape
    mask = np.zeros((h+2, w+2), np.uint8)
    flood = binary.copy()
    cv2.floodFill(flood, mask, (0, 0), 255)
    flood_inv = cv2.bitwise_not(flood)
    return binary | flood_inv

def process_frame(img, bg_inv):
    # crop
    # img = img[y1:y2, x1:x2]

    # invert
    img_inv = 255 - img
    img_inv = img_inv.astype(np.float32)

    # subtraction
    clean = img_inv - bg_inv
    clean[clean < 0] = 0

    # invert back
    clean = 255 - clean
    clean = clean.astype(np.uint8)

    # contrast (MATLAB imadjust)
    clahe = cv2.createCLAHE(clipLimit=7, tileGridSize=(6,6))
    clean = clahe.apply(clean)

    # gaussian filter
    clean = cv2.GaussianBlur(clean, (11,11), 0)

    # adaptive threshold (like MATLAB)
    bw = cv2.adaptiveThreshold(
        clean,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        31,
        11
    )
    kernel = np.ones((5,5), np.uint8)

    # Thicken edges
    bw = cv2.dilate(bw, kernel, iterations=2)

    # Close gaps
    bw = cv2.morphologyEx(bw, cv2.MORPH_CLOSE, kernel, iterations=2)


    # fill bubbles
    filled = fill_holes(bw)

    return clean, bw, filled


# -----------------------
# MAIN LOOP
vof_accumulator = None
n_frames = len(image_paths)

# store bubble data
bubble_data = []

for i, path in enumerate(image_paths):
    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    clean, bw, filled = process_frame(img, bg_inv)

    # initialize accumulator
    if vof_accumulator is None:
        vof_accumulator = np.zeros_like(filled, dtype=np.float32)

    vof_accumulator += filled.astype(np.float32) / n_frames

    # save outputs
    name = f"{i:05d}"
    cv2.imwrite(os.path.join(output_dir, f"{name}_clean.png"), clean)
    cv2.imwrite(os.path.join(output_dir, f"{name}_bw.png"), bw)
    cv2.imwrite(os.path.join(output_dir, f"{name}_filled.png"), filled)

    # -----------------------
    # bubble detection
    # -----------------------
    labeled = measure.label(filled)
    props = measure.regionprops(labeled)

    for p in props:
        radius = np.sqrt(p.area / np.pi)
        diameter = 2 * radius

        # record xy centroid (row, col)
        y, x = p.centroid

        bubble_data.append({
            "frame": i,
            "x": x,
            "y": y,
            "diameter_px": diameter,
            "area_px": p.area
        })

    if i % 10 == 0:
        print(f"Processed {i}/{n_frames}")

# -----------------------
# FINAL VOF IMAGE
# -----------------------
vof = (vof_accumulator * 255).astype(np.uint8)
cv2.imwrite(os.path.join(output_dir, "vof.png"), vof)

# -----------------------
# WRITE CSV
# -----------------------
df = pd.DataFrame(bubble_data)
df.to_csv(csv_file, index=False)
print(f"Saved bubble data to {csv_file}")

diameter=np.array(df["diameter_px"])

plt.figure()
plt.hist(diameter/333*25.4*2.5, bins=31)
plt.xlabel("diameter, mm")
plt.ylabel("Frequency")
plt.title("Histogram Distribution (31 Bins)")
plt.savefig('hist.jpg',dpi=300)


print("Done.")