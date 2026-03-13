import cv2
import numpy as np
from segment_anything import sam_model_registry, SamPredictor

# -----------------------
# USER PARAMETERS
# -----------------------

IMAGE_PATH = "050719-15scfh-250fps_C001H001S0001.png"
CHECKPOINT = "../defaultCheckpoint/sam_vit_b_01ec64.pth"

OUTPUT_IMAGE = "highlightedBubbles.jpg"

BOX = [168,150,610,875]  # region of interest

UPSCALE = 2
EDGE_THRESHOLD1 = 50
EDGE_THRESHOLD2 = 150

MIN_AREA = 20
MAX_AREA = 1500

PROMPT_STRIDE = 30   # distance between prompts along edges

# -----------------------
# LOAD IMAGE
# -----------------------

image = cv2.imread(IMAGE_PATH)
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# upscale to help detect tiny features
image = cv2.resize(image, None, fx=UPSCALE, fy=UPSCALE, interpolation=cv2.INTER_CUBIC)

x1,y1,x2,y2 = [v*UPSCALE for v in BOX]

# -----------------------
# EDGE DETECTION
# -----------------------

gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

edges = cv2.Canny(gray, EDGE_THRESHOLD1, EDGE_THRESHOLD2)

roi_edges = edges[y1:y2, x1:x2]

edge_points = np.column_stack(np.where(roi_edges > 0))

# convert to full image coordinates
edge_points[:,0] += y1
edge_points[:,1] += x1

# reduce density
edge_points = edge_points[::PROMPT_STRIDE]

print("Prompt points:", len(edge_points))

# -----------------------
# LOAD SAM
# -----------------------

sam = sam_model_registry["vit_b"](checkpoint=CHECKPOINT)
sam.to(device="cpu")

predictor = SamPredictor(sam)
predictor.set_image(image)

# -----------------------
# RUN SAM PROMPTS
# -----------------------

all_masks = []

for y,x in edge_points:

    point = np.array([[x,y]])
    label = np.array([1])

    masks, scores, logits = predictor.predict(
        point_coords=point,
        point_labels=label,
        box=np.array([x1,y1,x2,y2]),
        multimask_output=False
    )

    all_masks.append(masks[0])

print("SAM predictions:", len(all_masks))

# -----------------------
# COMBINE MASKS
# -----------------------

combined_mask = np.zeros_like(all_masks[0], dtype=np.uint8)

for m in all_masks:
    combined_mask = np.logical_or(combined_mask, m)

combined_mask = (combined_mask.astype(np.uint8))*255

# -----------------------
# CONTOUR DETECTION
# -----------------------

contours,_ = cv2.findContours(
    combined_mask,
    cv2.RETR_EXTERNAL,
    cv2.CHAIN_APPROX_SIMPLE
)

print("Raw contours:", len(contours))

output = image.copy()

diameters = []
count = 0

for cnt in contours:

    area = cv2.contourArea(cnt)

    if area < MIN_AREA or area > MAX_AREA:
        continue

    perimeter = cv2.arcLength(cnt,True)

    if perimeter == 0:
        continue

    diameter = 4*area/perimeter
    diameters.append(diameter)

    count += 1

    x,y,w,h = cv2.boundingRect(cnt)

    cv2.rectangle(output,(x,y),(x+w,y+h),(0,255,0),1)

    cv2.putText(
        output,
        str(count),
        (x,y-3),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.35,
        (255,0,0),
        1
    )

print("Detected features:", count)

# -----------------------
# SAVE OUTPUT
# -----------------------

output_bgr = cv2.cvtColor(output, cv2.COLOR_RGB2BGR)

cv2.imwrite(OUTPUT_IMAGE, output_bgr)

print("Saved labeled image:", OUTPUT_IMAGE)