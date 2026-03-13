import cv2
import numpy as np
import torch
from segment_anything import sam_model_registry, SamPredictor
import matplotlib.pyplot as plt

# -----------------------
# Load Image
# -----------------------
# image = cv2.imread("basic.jpeg")
image = cv2.imread("050719-15scfh-250fps_C001H001S0001.png")
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
image = cv2.resize(image, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)#upscale it

# load SAM
sam = sam_model_registry["vit_b"](checkpoint="../defaultCheckpoint/sam_vit_b_01ec64.pth")
predictor = SamPredictor(sam)
sam.to(device="cpu")
predictor.set_image(image)

# bounding box prompt
input_box = np.array([168,150,610,875])

# predict mask
masks, scores, logits = predictor.predict(
    box=input_box,
    multimask_output=False
)

mask = masks[0]

print(f"Total masks detected: {len(masks)}")

# -----------------------
# Create overlay image
# -----------------------
output_image = image.copy()
overlay = image.copy()

bubble_count = 0
d=[]
for mask_data in masks:
    mask = mask.astype(np.uint8)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    print('running...')
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area > 1500:
            continue

        perimeter = cv2.arcLength(cnt, True)
        if perimeter == 0:
            continue
        d.append(4*area/perimeter)
        # circularity = 4 * np.pi * (area / (perimeter ** 2))

        # if circularity > 0.75:
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

cv2.imwrite("highlightedBubbles.jpg", output_bgr)

d=np.array(d)

plt.figure()

plt.hist(d, bins=31)

plt.xlabel("diameter, pixels")

plt.ylabel("Frequency")

plt.title("Histogram Distribution (31 Bins)")

plt.savefig('hist.jpg',dpi=300)