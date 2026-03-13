import cv2
import numpy as np
import torch
from segment_anything import sam_model_registry, SamAutomaticMaskGenerator

# -----------------------
# Load SAM model
# -----------------------
# sam = sam_model_registry["vit_b"](checkpoint="./defaultCheckpoint/sam_vit_b_01ec64.pth")
# sam.to(device="cpu")
sam = sam_model_registry["default"](checkpoint="./defaultCheckpoint/sam_vit_h_4b8939.pth")
sam.to(device="cpu")

mask_generator = SamAutomaticMaskGenerator(
    sam,
    points_per_side=64,
    pred_iou_thresh=0.88,
    stability_score_thresh=0.92#,
    # min_mask_region_area=100  # removes tiny noise
)

# -----------------------
# Load Image
# -----------------------
image = cv2.imread("basic.jpeg")
# image = cv2.imread("050719-15scfh-250fps_C001H001S0001.png")
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# -----------------------
# Generate masks
# -----------------------
masks = mask_generator.generate(image)

print(f"Total masks detected: {len(masks)}")

# -----------------------
# Create overlay image
# -----------------------
output_image = image.copy()
overlay = image.copy()

bubble_count = 0

for mask_data in masks:
    mask = mask_data["segmentation"].astype(np.uint8)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    print('running...')
    for cnt in contours:
        area = cv2.contourArea(cnt)
        # if area < 100:
        #     continue

        perimeter = cv2.arcLength(cnt, True)
        if perimeter == 0:
            continue
        
        circularity = 4 * np.pi * (area / (perimeter ** 2))

        if circularity > 0.75:
            bubble_count += 1

            # Random color for each bubble
            color = np.random.randint(0, 255, size=3).tolist()

            # Fill bubble area
            cv2.drawContours(overlay, [cnt], -1, color, -1)

            # Draw outline
            cv2.drawContours(output_image, [cnt], -1, (0, 255, 0), 2)

            # Label bubble number
            M = cv2.moments(cnt)
            if M["m00"] != 0:
                cx = int(M["m10"] / M["m00"])
                cy = int(M["m01"] / M["m00"])
                cv2.putText(output_image, str(bubble_count), 
                            (cx, cy), 
                            cv2.FONT_HERSHEY_SIMPLEX, 
                            0.6, 
                            (255, 0, 0), 
                            2)

# Blend overlay with original image
alpha = 0.4
output_image = cv2.addWeighted(overlay, alpha, output_image, 1 - alpha, 0)

print(f"\nEstimated number of bubbles: {bubble_count}")

# Convert back to BGR for saving
output_bgr = cv2.cvtColor(output_image, cv2.COLOR_RGB2BGR)

cv2.imwrite("highlighted_bubbles.jpg", output_bgr)