import cv2
import mediapipe as mp
from pythonosc.udp_client import SimpleUDPClient
import math

# OSC settings
OSC_IP = "127.0.0.1"
OSC_PORT = 5002
client = SimpleUDPClient(OSC_IP, OSC_PORT)

# MediaPipe setup
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)
mp_draw = mp.solutions.drawing_utils

# Video capture setup
cap = cv2.VideoCapture(0)

def calculate_distance(point1, point2):
    """Calculate the Euclidean distance between two points."""
    return math.sqrt((point1.x - point2.x) ** 2 + (point1.y - point2.y) ** 2)

def detect_gesture(hand_label, landmarks, frame_width):
    """
    Detect gestures and send corresponding OSC messages.
    :param hand_label: 'leftHand' or 'rightHand'
    :param landmarks: MediaPipe hand landmarks
    :param frame_width: Width of the video frame for mirroring
    """
    # Mirror the X coordinates
    for lm in landmarks:
        lm.x = 1 - lm.x  # Mirror X coordinates

    # Swap hand labels due to mirroring
    if hand_label == "leftHand":
        hand_label = "rightHand"
    else:
        hand_label = "leftHand"

    # Extract relevant landmarks
    thumb_tip = landmarks[4]
    index_tip = landmarks[8]
    middle_tip = landmarks[12]
    wrist = landmarks[0]

    # Movement directions
    if hand_label == "leftHand":
        if index_tip.y < wrist.y - 0.2:  # Move up
            client.send_message("/blueUp", 1)
        elif index_tip.y > wrist.y + 0.2:  # Move down
            client.send_message("/blueDown", 1)

        if index_tip.x < wrist.x - 0.1:  # Move left
            client.send_message("/blueLeft", 1)
        elif index_tip.x > wrist.x + 0.1:  # Move right
            client.send_message("/blueRight", 1)

        # Size adjustments
        if calculate_distance(thumb_tip, index_tip) > 0.15:  # Spread fingers
            client.send_message("/blueSizeIncrease", 1)
        elif calculate_distance(thumb_tip, index_tip) < 0.05:  # Close fingers
            client.send_message("/blueSizeDecrease", 1)

        # Swipe gesture for toggling
        if middle_tip.x > wrist.x + 0.3:
            client.send_message("/toggleBlueSphere", 1)

    elif hand_label == "rightHand":
        if index_tip.y < wrist.y - 0.2:  # Move up
            client.send_message("/redUp", 1)
        elif index_tip.y > wrist.y + 0.2:  # Move down
            client.send_message("/redDown", 1)

        if index_tip.x < wrist.x - 0.1:  # Move left
            client.send_message("/redLeft", 1)
        elif index_tip.x > wrist.x + 0.1:  # Move right
            client.send_message("/redRight", 1)

        # Size adjustments
        if calculate_distance(thumb_tip, index_tip) > 0.15:  # Spread fingers
            client.send_message("/redSizeIncrease", 1)
        elif calculate_distance(thumb_tip, index_tip) < 0.08:  # Close fingers
            client.send_message("/redSizeDecrease", 1)

        # Swipe gesture for toggling
        if middle_tip.x > wrist.x + 0.3:
            client.send_message("/toggleRedSphere", 1)

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        print("Error: Unable to read from the camera.")
        break

    # Convert the frame to RGB for MediaPipe
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)

    # Process detected hands
    if results.multi_hand_landmarks:
        for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
            # Determine hand label ('leftHand' or 'rightHand')
            if handedness.classification[0].label.lower() == 'left':
                label = 'leftHand'
            else:
                label = 'rightHand'

            # Detect gesture and send OSC message
            detect_gesture(label, hand_landmarks.landmark, frame.shape[1])

            # Draw hand landmarks on the original frame
            # mp_draw.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

    # Create a mirrored copy of the frame for display
    frame_flipped = cv2.flip(frame, 1)

    # Display the mirrored frame
    cv2.imshow("ReimaginingTheBuchlaLightning", frame_flipped)
    
    # Exit with 'Esc' key
    if cv2.waitKey(1) & 0xFF == 27:
        break

# Release resources
cap.release()
cv2.destroyAllWindows()

