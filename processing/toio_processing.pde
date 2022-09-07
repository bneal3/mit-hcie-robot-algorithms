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
int COLLISION_TIMER_LIMIT = 500;

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
boolean timer = false;

boolean test = true;

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
          fill(0, 255, 0);
        } else {
          fill(255, 0, 0);
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
      translate(objects.get(i).collisions.get(j).x, objects.get(i).collisions.get(j).y);
      rotate(objects.get(i).collisions.get(j).deg * (PI / 180));
      rect(-5, -5, 10, 10);
      popMatrix();
      // TODO: Create new shape from collisions by finding collision closest in proximity and drawing line, if line drawn, then go to next closest (only 2 though)
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
        float angle = (TWO_PI * i) / nCubes;
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
        fill(0, 255, 0);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        // FLOW: Get target angle difference
        float da = abs(cubes[i].deg - cubes[i].targetAngle);
        float daOverflow = abs(cubes[i].deg - (cubes[i].targetAngle + 360));
        if(da <= 7 || daOverflow <= 7) {
          if(cubes[i].isRotating) { cubes[i].isRotating = false; }
          // println("isRotating from update: " + cubes[i].isRotating);
          moveCube(i, cubes[i].targetx, cubes[i].targety);
          if(cubes[i].track) { setGridTraveled(cubes[i].x, cubes[i].y); }
        } else {
          // println("da " + da);
          // println("daOverflow " + daOverflow);
          if(!cubes[i].isRotating) { cubes[i].isRotating = true; }
          rotateCube(i, cubes[i].targetAngle);
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
