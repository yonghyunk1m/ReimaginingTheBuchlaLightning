import netP5.*;
import oscP5.*;

float x1, y1, x2, y2;
float speed = 5;
float size1 = 30, size2 = 30;
boolean[] keys = new boolean[256];
boolean blueSphereOn = true;
boolean redSphereOn = true;

float leftHandX = -1, leftHandY =-1;
float rightHandX = -1, rightHandY = -1;
float leftHandSize = 30, rightHandSize = 30;

// Declare OSC communication and hand landmarks
OscP5 oscP5;
NetAddress address;

// State Definitions
// 0 = Intro Screen
// 1 = Input Modality Selection Screen
// 2 = Computer Vision Instructions
// 3 = Keyboard Instructions
// 4 = Computer Vision Gameplay
// 5 = Keyboard Gameplay
int state = 0;

void setup() {
  size(450, 450, P3D); 
  oscP5 = new OscP5(this, 5002); // OSC Receive Port
  address = new NetAddress("localhost", 5001); // OSC Send Target
  
  // Initial Sphere location
  x1 = width / 3;
  y1 = height / 2; 
  x2 = 2 * width / 3;
  y2 = height / 2;
  
  textAlign(CENTER, CENTER);
  textSize(16);
}

void draw() {
  if (state == 0) {
    drawIntroScreen(); // Intro screen
  } else if (state == 1) {
    drawInputSelectionScreen(); // Input selection screen
  } else if (state == 2) {
    drawInstructionScreen(); // Computer Vision instructions
  } else if (state == 3) {
    drawInstructionScreen(); // Keyboard instructions
  } else if (state == 4) {
    drawMainGameWithVision(); // Computer Vision gameplay
  } else if (state == 5) {
    drawMainGameWithKeyboard(); // Keyboard gameplay
  }
}


void drawIntroScreen() {
  background(0);
  
  fill(255);
  textSize(24);
  text("Welcome to NeoLightning", width/2, height/3);
  textSize(16);
  text("Click to see instructions", width/2, 2*height/3);
}

void drawInputSelectionScreen() {
  background(0);
  fill(255);
  textSize(20);
  text("Select Input Method", width / 2, height / 4);
  textSize(16);
  text("Press 1: Camera (Hand Motion) Input", width / 2, height / 2 - 20);
  text("Press 2: Keyboard Input", width / 2, height / 2 + 20);
}

void drawInstructionScreen() {
  background(0);

  fill(255);
  textSize(20);
  if (state == 2) {  // Computer Vision Instructions
    text("Instructions: Camera Input Mode", width / 2, height / 6);
    textSize(14);
    text("Raise Hand Up: Sphere moves up", width / 2, height / 3);
    text("Lower Hand Down: Sphere moves down", width / 2, height / 3 + 30);
    text("Tilt Hand Left: Sphere moves left", width / 2, height / 3 + 60);
    text("Tilt Hand Right: Sphere moves right", width / 2, height / 3 + 90);
    text("Open Thumb and Index: Increase sphere size", width / 2, height / 3 + 120);
    text("Close Thumb and Index: Decrease sphere size", width / 2, height / 3 + 150);
    text("Swipe Hand Outward: Toggle sphere visibility", width / 2, height / 3 + 180);
    textSize(16);
    text("Click to start the instrument", width / 2, 5 * height / 6);
  } else if (state == 3) {  // Keyboard Instructions
    text("Instructions: Keyboard Mode", width / 2, height / 6);
    textSize(14);
    text("WASD: Move blue sphere", width / 2, height / 3);
    text("Arrow keys: Move red sphere", width / 2, height / 3 + 30);
    text("Q/Z: Adjust blue sphere size", width / 2, height / 3 + 60);
    text("E/C: Adjust red sphere size", width / 2, height / 3 + 90);
    text("O: Toggle blue sphere", width / 2, height / 3 + 120);
    text("P: Toggle red sphere", width / 2, height / 3 + 150);
    textSize(16);
    text("Click to start the instrument", width / 2, 5 * height / 6);
  }
}

void drawMainGameWithVision() {
  background(0);
  displayGameText();

  // Computer Vision: Blue Sphere
  if (blueSphereOn) {
    if (leftHandX != -1 && leftHandY != -1) {

      size1 = constrain(leftHandSize, 10, 100);

      x1 = constrain(leftHandX, size1 / 2, width - size1 / 2);
      y1 = constrain(leftHandY, size1 / 2, height - size1 / 2);
    }
    drawSphere(x1, y1, size1, color(0, 0, 255), "L");
  }

  // Computer Vision: Red Sphere
  if (redSphereOn) {
    if (rightHandX != -1 && rightHandY != -1) {

      size2 = constrain(rightHandSize, 10, 100);

      x2 = constrain(rightHandX, size2 / 2, width - size2 / 2);
      y2 = constrain(rightHandY, size2 / 2, height - size2 / 2);
    }
    drawSphere(x2, y2, size2, color(255, 0, 0), "R");
  }

  sendOscCoordinates();
}


void drawMainGameWithKeyboard() {
  background(0);
  
  // Text Display
  displayGameText();
  
  // Blue Sphere
  if (blueSphereOn) {
    handleBlueSphereMovement();
    x1 = constrain(x1, size1 / 2, width - size1 / 2);
    y1 = constrain(y1, size1 / 2, height - size1 / 2);
    drawSphere(x1, y1, size1, color(0, 0, 255), "L");
  }
  
  // Red Sphere
  if (redSphereOn) {
    handleRedSphereMovement();
    x2 = constrain(x2, size2 / 2, width - size2 / 2);
    y2 = constrain(y2, size2 / 2, height - size2 / 2);
    drawSphere(x2, y2, size2, color(255, 0, 0), "R");
  }

  sendOscCoordinates();
}

// Text Display
void displayGameText() {
  fill(255);
  textAlign(RIGHT, TOP);
  text("High Pitch ", width - 10, 10);

  
  textAlign(RIGHT, BOTTOM);
  text("Low Pitch ", width - 10, height - 10);
  
  textAlign(CENTER, BOTTOM);
  text("NeoLightning", width/2, height - 10);
}

void drawSphere(float x, float y, float size, int col, String label) {
  pushMatrix();
  translate(x, y, 0);
  fill(col);
  noStroke();
  sphere(size / 2);
  popMatrix();
  
  fill(255);
  text(label, x, y);
}

// Blue Sphere Movement (Keyboard-Control)
void handleBlueSphereMovement() {
  if (keys['A']) x1 -= speed;
  if (keys['D']) x1 += speed;
  if (keys['W']) y1 -= speed;
  if (keys['S']) y1 += speed;
  x1 = constrain(x1, size1 / 2, width - size1 / 2);
  y1 = constrain(y1, size1 / 2, height - size1 / 2);
}

// Red Sphere Movement (Keyboard-Control)
void handleRedSphereMovement() {
  if (keys[LEFT]) x2 -= speed;
  if (keys[RIGHT]) x2 += speed;
  if (keys[UP]) y2 -= speed;
  if (keys[DOWN]) y2 += speed;
  x2 = constrain(x2, size2 / 2, width - size2 / 2);
  y2 = constrain(y2, size2 / 2, height - size2 / 2);
}

void mouseClicked() {
  if (state == 0) {
    state = 1; // Switch to input selection screen
  } else if (state == 2) {
    state = 4; // Switch to Computer Vision Gameplay
  } else if (state == 3) {
    state = 5; // Switch to Keyboard Gameplay
  }
}

void keyPressed() {
  keys[keyCode] = true;

  // Log the pressed key to the console
  println("Key Pressed: " + key + " (keyCode: " + keyCode + ")");

  // Handle uppercase letters for keyboard controls
  if (key >= 'A' && key <= 'Z') {
    keys[key] = keys[key + 32] = true;
  }

  // Input modality selection (state == 1)
  if (state == 1) {
    if (key == '1') {
      state = 2; // Transition to Computer Vision Instructions
    } else if (key == '2') {
      state = 3; // Transition to Keyboard Instructions
    }
  }
}

void keyReleased() {
  keys[keyCode] = false;
  
  // Log the released key to the console
  println("Key Released: " + key + " (keyCode: " + keyCode + ")");

  // Handle uppercase letters for keyboard controls
  if (key >= 'A' && key <= 'Z') {
    keys[key] = keys[key + 32] = false; // Map uppercase to lowercase
  }

  // Handle specific keys for blue and red spheres in Keyboard mode (state == 5)
  if (state == 5) { // Ensure we're in Keyboard Gameplay
    if (key == 'q' || key == 'Q') size1 = min(size1 + 1, 100); // Blue sphere size increase
    if (key == 'z' || key == 'Z') size1 = max(size1 - 1, 10);  // Blue sphere size decrease
    if (key == 'e' || key == 'E') size2 = min(size2 + 1, 100); // Red sphere size increase
    if (key == 'c' || key == 'C') size2 = max(size2 - 1, 10);  // Red sphere size decrease

    if (key == 'o' || key == 'O') { // Toggle blue sphere
      blueSphereOn = !blueSphereOn;
      OscMessage toggleBlue = new OscMessage("/toggleBlue");
      toggleBlue.add(blueSphereOn ? 1 : 0);
      oscP5.send(toggleBlue, address);
    }

    if (key == 'p' || key == 'P') { // Toggle red sphere
      redSphereOn = !redSphereOn;
      OscMessage toggleRed = new OscMessage("/toggleRed");
      toggleRed.add(redSphereOn ? 1 : 0);
      oscP5.send(toggleRed, address);
    }
  }
}

// Receiving Hand Information through ComputerVision
void oscEvent(OscMessage msg) {
  String addr = msg.addrPattern();
  println("Received OSC Message: " + addr); // Debugging OSC messages

  // Map left hand data to the blue sphere
  if (addr.equals("/rightHand")) {
    rightHandX = constrain(map(msg.get(0).floatValue(), 0, 1, 0, width), size2 / 2, width - size2 / 2);
    rightHandY = constrain(map(msg.get(1).floatValue(), 0, 1, height, 0), size2 / 2, height - size2 / 2);
    rightHandSize = constrain(msg.get(2).floatValue() * 50, 10, 100);
  }

  // Map right hand data to the red sphere
  else if (addr.equals("/leftHand")) {
    leftHandX = constrain(map(msg.get(0).floatValue(), 0, 1, 0, width), size1 / 2, width - size1 / 2);
    leftHandY = constrain(map(msg.get(1).floatValue(), 0, 1, height, 0), size1 / 2, height - size1 / 2);
    leftHandSize = constrain(msg.get(2).floatValue() * 50, 10, 100);
  }
  
  // Handle gestures for blue sphere (left hand)
  else if (addr.equals("/blueUp")) {
    y1 -= speed;
    y1 = constrain(y1, size1 / 2, height - size1 / 2); // Ensure within vertical bounds
  }
  else if (addr.equals("/blueDown")) {
    y1 += speed;
    y1 = constrain(y1, size1 / 2, height - size1 / 2); // Ensure within vertical bounds
  }
  else if (addr.equals("/blueLeft")) {
    x1 -= speed;
    x1 = constrain(x1, size1 / 2, width - size1 / 2); // Ensure within horizontal bounds
  }
  else if (addr.equals("/blueRight")) {
    x1 += speed;
    x1 = constrain(x1, size1 / 2, width - size1 / 2); // Ensure within horizontal bounds
  }
  else if (addr.equals("/blueSizeIncrease")) {
    size1 = min(size1 + 1, 100);
  }
  else if (addr.equals("/blueSizeDecrease")) {
    size1 = max(size1 - 1, 10);
  }
  else if (addr.equals("/toggleBlueSphere")) {
    blueSphereOn = !blueSphereOn;
  }

  // Handle gestures for red sphere (right hand)
  else if (addr.equals("/redUp")) {
    y2 -= speed;
    y2 = constrain(y2, size2 / 2, height - size2 / 2); // Ensure within vertical bounds
  }
  else if (addr.equals("/redDown")) {
    y2 += speed;
    y2 = constrain(y2, size2 / 2, height - size2 / 2); // Ensure within vertical bounds
  }
  else if (addr.equals("/redLeft")) {
    x2 -= speed;
    x2 = constrain(x2, size2 / 2, width - size2 / 2); // Ensure within horizontal bounds
  }
  else if (addr.equals("/redRight")) {
    x2 += speed;
    x2 = constrain(x2, size2 / 2, width - size2 / 2); // Ensure within horizontal bounds
  }
  else if (addr.equals("/redSizeIncrease")) {
    size2 = min(size2 + 1, 100);
  }
  else if (addr.equals("/redSizeDecrease")) {
    size2 = max(size2 - 1, 10);
  }
  else if (addr.equals("/toggleRedSphere")) {
    redSphereOn = !redSphereOn;
  }
}


void sendOscCoordinates() {
  OscMessage distance = new OscMessage("/Distance");
  float d = calcDistance(x1, y1, size1, x2, y2, size2);
  distance.add(d);
  oscP5.send(distance, address);
  
  OscMessage redXMsg = new OscMessage("/RedX");
  redXMsg.add(map(x2, 0, width, 82, 329));
  redXMsg.add(x2);
  oscP5.send(redXMsg, address);
  
  OscMessage redYMsg = new OscMessage("/RedY");
  redYMsg.add(map(y2, height, 0, 82, 329));
  oscP5.send(redYMsg, address);
  
  OscMessage blueXMsg = new OscMessage("/BlueX");
  blueXMsg.add(map(x1, 0, width, 82, 329));
  blueXMsg.add(x1);
  oscP5.send(blueXMsg, address);
  
  OscMessage blueYMsg = new OscMessage("/BlueY");
  blueYMsg.add(map(y1, height, 0, 82, 329));
  oscP5.send(blueYMsg, address);
  
  OscMessage blueSizeMsg = new OscMessage("/BlueSize");
  blueSizeMsg.add(size1);
  oscP5.send(blueSizeMsg, address);
  
  OscMessage redSizeMsg = new OscMessage("/RedSize");
  redSizeMsg.add(size2);
  oscP5.send(redSizeMsg, address);
  
  OscMessage overlapMsg = new OscMessage("/SpheresOverlap");
  int overlapState = spheresOverlap(x1, y1, size1, x2, y2, size2) ? 1 : 0;
  if(overlapState == 1){
    overlapMsg.add(overlapState);
    oscP5.send(overlapMsg, address);
  }
}

float calcDistance(float x1, float y1, float size1, float x2, float y2, float size2){
  float distance = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  return distance;
}


boolean spheresOverlap(float x1, float y1, float size1, float x2, float y2, float size2) {
  float distance = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  return distance <= (size1 / 2 + size2 / 2);
}
