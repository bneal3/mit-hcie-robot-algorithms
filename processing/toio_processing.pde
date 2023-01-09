import oscP5.*;
import netP5.*;

// VARIABLE: Constants
int OSC_PORT = 3333;
int SERVER_PORT = 3334;
int FRAME_RATE = 30;
int MAT_STARTING_POS = 45;
int MAT_SIZE = 410;
int CUBE_SIZE = 30;
int GRID_WIDTH = floor((MAT_SIZE - CUBE_SIZE) / CUBE_SIZE);
int GRID_HEIGHT = floor((MAT_SIZE - CUBE_SIZE) / CUBE_SIZE);
int SQUARE_WIDTH = (MAT_SIZE - CUBE_SIZE) / GRID_WIDTH;
int SQUARE_HEIGHT = (MAT_SIZE - CUBE_SIZE) / GRID_HEIGHT;
int POSITION_TIMER_LIMIT = 1500;
int DEGREE_TIMER_LIMIT = 250;
int COLLISION_TIMER_LIMIT = 500;
int BACKUP_TIMER_LIMIT = 300;
int SHIFT_TIMER_LIMIT = 200;
int ATTACK_TIMER_LIMIT = 1000;
int LOST_TIMER_LIMIT = 2000;
int TRANSPORT_STARTING_OFFSET = 25;

// VARIABLE: OSC object
OscP5 oscP5;
// VARIABLE: Where to send the commands to
NetAddress[] server;

// VARIABLE: Cube array
Cube[] cubes;

// VARIABLE: Drive global variables
boolean mouseDrive = false;
boolean chase = false;
boolean spin = false;
boolean probe = false;
boolean transport = false;

// VARIABLE: Timers
boolean positionTimer = false;
boolean degreeTimer = false;
boolean collisionTimer = false;
boolean backupTimer = false;
boolean shiftTimer = false;
boolean attackTimer = false;
boolean lostTimer = false;

boolean test = false;

// VARIABLE: Grid board
GridPosition[][] grid;

// VARIABLE: Object repository
ArrayList<Object> objects;

void settings() {
  size(1000, 1000, P3D);
}

ArrayList<JSONObject> getActiveCubes(Cube cubes[]) {
  ArrayList<JSONObject> activeCubes = new ArrayList<JSONObject>();
  for(int i = 0; i < cubes.length; i++) {
    if(cubes[i].isLost == false) {
      JSONObject activeCube = new JSONObject();
      activeCube.setInt("id", i);
      activeCubes.add(activeCube);
    }
  }
  return activeCubes;
}

// TODO: Videos: (Sweeping, Object Detection/Moving)
// TODO: Pictures: (Sweeping w/ 1, Sweeping w/ 2, Object Detection Mid-Detect, Object Detection Full-Detect, Object Moving Setup, Object Moving Positioning, Object Moving Contact, Object Moving Movement)

void setup() {
  // Constant Instantiation
  // Directions
  Directions.put("Up", 0);
  Directions.put("Down", 1);
  Directions.put("Left", 2);
  Directions.put("Right", 3);
  // DetectStates
  DetectStates.put("None", -1);
  DetectStates.put("Backup", 0);
  DetectStates.put("Shift", 1);
  DetectStates.put("Attack", 2);
  DetectStates.put("Lost", 3);
  // TransportStates
  TransportStates.put("None", -1);
  TransportStates.put("Position", 0);
  TransportStates.put("Rotate", 1);
  TransportStates.put("Idle", 2);

  // FLOW: OSC Setup
  // FLOW: Receive messages on port 3333
  oscP5 = new OscP5(this, OSC_PORT);

  // FLOW: Send back to the BLE interface
  // NOTE: We can have multiple BLE bridges
  server = new NetAddress[1]; //only one for now
  // FLOW: send on port 3334
  server[0] = new NetAddress("127.0.0.1", SERVER_PORT);
  //server[1] = new NetAddress("192.168.0.103", 3334);
  //server[2] = new NetAddress("192.168.200.12", 3334);

  // FLOW: Create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i < cubes.length; ++i) {
    cubes[i] = new Cube(i, true);
  }

  // FLOW: Instantiate grid
  grid = new GridPosition[GRID_WIDTH][GRID_HEIGHT];
  for (int i = 0; i < GRID_WIDTH; i++) {
    for (int j = 0; j < GRID_HEIGHT; j++) {
      GridPosition position = new GridPosition(i, j); // new GridPosition(MAT_STARTING_POS + (i * SQUARE_WIDTH), MAT_STARTING_POS + (j * SQUARE_HEIGHT));
      grid[i][j] = position;
      // if(j < GRID_HEIGHT / 2) {
      //   grid[i][j].traveled = true;
      // }
    }
  }

  // FLOW: Instantiate objects ArrayList
  objects = new ArrayList<Object>();

  // NOTE: Do not send TOO MANY PACKETS - we'll be updating the cubes every frame, so don't try to go too high
  frameRate(FRAME_RATE);
}

void draw() {
  motion(0);
  background(255);
  stroke(0);
  long now = System.currentTimeMillis();

  // FLOW: Draw the "mat"
  fill(255);
  rect(MAT_STARTING_POS, MAT_STARTING_POS, MAT_SIZE, MAT_SIZE);

  if (test) {
    // FLOW: Draw the test grid
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid.length; j++) {
        if(!grid[i][j].traveled) {
          fill(255, 255, 255);
        } else {
          fill(173, 216, 230);
        }
        rect(grid[i][j].xCoordinate(grid[i][j]) - (CUBE_SIZE / 2), grid[i][j].yCoordinate(grid[i][j]) - (CUBE_SIZE / 2), SQUARE_WIDTH, SQUARE_HEIGHT);
      }
    }
  }

  // FLOW: Draw the cubes
  for (int i = 0; i < cubes.length; ++i) {
    if (cubes[i].isLost == false) {
      pushMatrix();
      translate(cubes[i].x, cubes[i].y);
      rotate(cubes[i].deg * (PI / 180));
      rect(-(CUBE_SIZE / 2), -(CUBE_SIZE / 2), CUBE_SIZE, CUBE_SIZE);
      rect(0, -5, 15, 10);
      popMatrix();
    }
  }

  // FLOW: Object collision detection
  for (int i = 0; i < objects.size(); i++) {
    for (int j = 0; j < objects.get(i).collisions.size(); j++) {
      // FLOW: Draw collision points from object collisions
      pushMatrix();
      stroke(255, 127, 0);
      fill(255, 127, 0);
      translate(objects.get(i).collisions.get(j).x, objects.get(i).collisions.get(j).y);
      rotate(objects.get(i).collisions.get(j).deg * (PI / 180));
      rect(-5, -5, 10, 10);
      popMatrix();
      // FLOW: Create new shape from collisions by finding collision closest in proximity and drawing line, if line drawn, then go to next closest (only 2 though)
      if(j > 0) {
        pushMatrix();
        stroke(255, 127, 0);
        line(objects.get(i).collisions.get(j).x, objects.get(i).collisions.get(j).y, objects.get(i).collisions.get(j - 1).x, objects.get(i).collisions.get(j - 1).y);
        if(j == objects.get(i).collisions.size() - 1) {
          line(objects.get(i).collisions.get(j).x, objects.get(i).collisions.get(j).y, objects.get(i).collisions.get(0).x, objects.get(i).collisions.get(0).y);
        }
        popMatrix();
      }
    }
  }

  if (chase) {
    cubes[0].targetx = cubes[0].x;
    cubes[0].targety = cubes[0].y;
    cubes[1].targetx = cubes[0].x;
    cubes[1].targety = cubes[0].y;
  }

  // FLOW: Makes a circle with n cubes
  if (mouseDrive) {
    // FLOW: Target position calculation
    float mx = (mouseX);
    float my = (mouseY);
    float cx = (MAT_STARTING_POS + MAT_SIZE) / 2;
    float cy = (MAT_STARTING_POS + MAT_SIZE) / 2;

    float mulr = 180.0;

    float aMouse = atan2(my - cy, mx - cx);
    float r = sqrt((mx - cx) * (mx - cx) + (my - cy) * (my - cy));
    r = min(mulr, r);
    for (int i = 0; i < nCubes; ++i) {
      if (cubes[i].isLost == false) {
        float angle = (TWO_PI * 0) / nCubes;
        float na = aMouse + angle;
        float tax = cx + r*cos(na);
        float tay = cy + r*sin(na);
        fill(255, 0, 0);
        ellipse(tax, tay, 10, 10);
        cubes[i].targetx = tax;
        cubes[i].targety = tay;
      }
    }
  }

  if(spin) {
    motorControl(0, -100, 100, 30);
  }

  if(chase || mouseDrive) {
    // FLOW: Do the actual aim
    for (int i = 0; i < nCubes; ++i) {
      if (cubes[i].isLost == false) {
        fill(0, 255, 0);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        aimCubeSpeed(i, cubes[i].targetx, cubes[i].targety);
      }
    }
  }

  if(probe) {
    probe();
    for(int i = 0; i < nCubes; i++) {
      if(!cubes[i].isLost) {
        fill(255, 127, i * 50);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        // FLOW: Get target angle difference
        float da = abs(cubes[i].deg - cubes[i].targetAngle);
        float daOverflow = abs(cubes[i].deg - (cubes[i].targetAngle + 360));
        // FLOW: Move toio if difference in angle is less than 7, rotate it if not
        // println("detectState: " + cubes[i].detectState);
        if(da <= 7 || daOverflow <= 7) {
          if(cubes[i].isRotating) { cubes[i].isRotating = false; }
          if(cubes[i].detectState == DetectStates.get("None")) { // FLOW: If in probe use moveCube
            // FLOW: Recompute target angle
            float angleToRotate = getAngleToTargetPosition(cubes[i], new Position((int)(cubes[i].targetx), (int)(cubes[i].targety)));
            float datr = abs(angleToRotate - cubes[i].targetAngle);
            float datrOverflow = abs(angleToRotate - (cubes[i].targetAngle + 360));
            if(datr > 7 || datrOverflow > 7) { cubes[i].targetAngle = angleToRotate; }
            moveCube(i, cubes[i].targetx, cubes[i].targety);
          } else { // FLOW: If in detect mode, use motorControl
            // println("targetAngle: " + cubes[i].targetAngle);
            // println("targetAngle: " + cubes[i].deg);
            cubes[i].targetAngle = -1;
            motorControl(i, cubes[i].detectMotorControl[0], cubes[i].detectMotorControl[1], (0));
          }
          if(cubes[i].track) { setGridTraveled(cubes[i].x, cubes[i].y); }
        } else if(cubes[i].targetAngle > -1) {
          if(!cubes[i].isRotating) { cubes[i].isRotating = true; }
          // println("da: " + da);
          // println("daOverflow: " + daOverflow);
          // println("degree: " + cubes[i].deg);
          // println("targetAngle: " + cubes[i].targetAngle);
          rotateCube(i, cubes[i].targetAngle);
        }
      }
    }
  }

  if(transport) {
    if(objects.size() > 0) {
      transport(Directions.get("Right"));
      // FLOW: Check if all cubes are in position
      boolean areCubesInPosition = true;
      for(int i = 0; i < nCubes; i++) {
        if(!cubes[i].isLost) {
          if(cubes[i].transportState != TransportStates.get("Idle")) {
            areCubesInPosition = false;
          }
        }
      }
      for(int i = 0; i < nCubes; i++) {
        if(!cubes[i].isLost) {
          // FLOW: Fill target position for cube
          fill(255, 127, i * 50);
          // ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
          // FLOW: Get target angle difference
          float da = abs(cubes[i].deg - cubes[i].targetAngle);
          float daOverflow = abs(cubes[i].deg - (cubes[i].targetAngle + 360));
          // FLOW: Move toio if difference in angle is less than 7, rotate it if not
          // println("transportState: " + cubes[i].transportState);
          if(da <= 7 || daOverflow <= 7) {
            if(cubes[i].isRotating) { cubes[i].isRotating = false; }
            if(cubes[i].transportState == TransportStates.get("Position")) { // FLOW: If in position use moveCube
              // FLOW: Recompute target angle
              float angleToRotate = getAngleToTargetPosition(cubes[i], new Position((int)(cubes[i].targetx), (int)(cubes[i].targety)));
              float datr = abs(angleToRotate - cubes[i].targetAngle);
              float datrOverflow = abs(angleToRotate - (cubes[i].targetAngle + 360));
              if(datr > 7 || datrOverflow > 7) { cubes[i].targetAngle = angleToRotate; }
              moveCube(i, cubes[i].targetx, cubes[i].targety);
            } else if(cubes[i].transportState == TransportStates.get("Idle")) {
              cubes[i].targetAngle = -1;
              if(areCubesInPosition) {
                motorControl(i, cubes[i].transportMotorControl[0], cubes[i].transportMotorControl[1], (0));
              }
            }
          } else if(cubes[i].targetAngle > -1) {
            if(!cubes[i].isRotating) { cubes[i].isRotating = true; }
            rotateCube(i, cubes[i].targetAngle);
          }
        }
      }
    }
  }

  // FLOW: Did we loose some cubes?
  for(int i = 0; i < nCubes; i++) {
    // NOTE: 500ms since last update
    cubes[i].p_isLost = cubes[i].isLost;
    if(cubes[i].lastUpdate < now - 1500 && cubes[i].isLost == false) {
      cubes[i].isLost = true;
    }
  }
}

void transport(int direction) {
  ArrayList<JSONObject> activeCubes = getActiveCubes(cubes);
  for (int i = 0; i < activeCubes.size(); i++) {
    // FLOW: Necessary variables for calculations
    int iter = activeCubes.get(i).getInt("id");
    if(cubes[iter].transportState == TransportStates.get("Position")) {
      float distanceFromTarget = cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety);
      if(distanceFromTarget < 14) {
        float angleToRotate = -1;
        if(direction == Directions.get("Right")) {
          angleToRotate = getAngleToTargetPosition(cubes[iter], new Position((int)(cubes[iter].targetx + TRANSPORT_STARTING_OFFSET), (int)(cubes[iter].targety)));
        }
        cubes[iter].targetAngle = angleToRotate;
        cubes[iter].transportState = TransportStates.get("Rotate");
      }
    } else if(cubes[iter].transportState == TransportStates.get("Rotate")) {
      float da = abs(cubes[i].deg - cubes[i].targetAngle);
      float daOverflow = abs(cubes[i].deg - (cubes[i].targetAngle + 360));
      if(da <= 7 || daOverflow <= 7) {
        cubes[iter].transportMotorControl[0] = 75;
        cubes[iter].transportMotorControl[1] = 75;
        cubes[iter].transportState = TransportStates.get("Idle");
      }
    }
  }
}
