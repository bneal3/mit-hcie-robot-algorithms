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

boolean test = true;

// VARIABLE: Grid board
IntDict[][] grid;

// VARIABLE: Object repository
ArrayList<Object> objects;

void settings() {
  size(1000, 1000, P3D);
}

void setup() {
  // Constant Instantiation
  // Directions
  Directions.put("Up", 0);
  Directions.put("Down", 1);
  Directions.put("Left", 2);
  Directions.put("Right", 3);
  // DetectionStates
  DetectionStates.put("None", -1);
  DetectionStates.put("Backup", 0);
  DetectionStates.put("Shift", 1);
  DetectionStates.put("Probe", 2);
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
  grid = new IntDict[GRID_WIDTH][GRID_HEIGHT];
  for (int i = 0; i < GRID_WIDTH; i++) {
    for (int j = 0; j < GRID_HEIGHT; j++) {
      IntDict gridItem = new IntDict();
      gridItem.set("x", MAT_STARTING_POS + (i * SQUARE_WIDTH));
      gridItem.set("y", MAT_STARTING_POS + (j * SQUARE_HEIGHT));
      gridItem.set("traveled", 0);
      grid[i][j] = gridItem;
    }
  }

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
        if(grid[i][j].get("traveled") == 0) {
          fill(0, 255, 0);
        } else {
          fill(255, 0, 0);
        }
        rect((CUBE_SIZE / 2) + grid[i][j].get("x"), (CUBE_SIZE / 2) + grid[i][j].get("y"), SQUARE_WIDTH, SQUARE_HEIGHT);
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

  if (spin) {
    motorControl(0, -100, 100, 30);
  }

  if (chase || mouseDrive) {
    // FLOW: Do the actual aim
    for (int i = 0; i < nCubes; ++i) {
      if (cubes[i].isLost == false) {
        fill(0, 255, 0);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        aimCubeSpeed(i, cubes[i].targetx, cubes[i].targety);
      }
    }
  }

  if (false) {
    probe();
    for (int i = 0; i < nCubes; ++i) {
      if (cubes[i].isLost == false) {
        fill(0, 255, 0);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        // FLOW: Get target angle difference
        float da = abs(cubes[i].deg - cubes[i].targetAngle);
        float daOverflow = abs(cubes[i].deg - (cubes[i].targetAngle + 360));
        if (da <= 6 || daOverflow <= 6) {
          moveCube(i, cubes[i].targetx, cubes[i].targety);
          if (cubes[i].track) { setGridTraveled(cubes[i].x, cubes[i].y); }
        } else {
          // println("Actual Angle: " + cubes[i].deg);
          // println("Target Angle: " + cubes[i].targetAngle);
          rotateCube(i, cubes[i].targetAngle);
        }
      }
    }
  }

  // FLOW: Did we loose some cubes?
  for (int i = 0; i < nCubes; ++i) {
    // NOTE: 500ms since last update
    cubes[i].p_isLost = cubes[i].isLost;
    if (cubes[i].lastUpdate < now - 1500 && cubes[i].isLost == false) {
      cubes[i].isLost = true;
    }
  }
}

// FUNCTION: Probe
void probe() {
  // FLOW: Check if all grid squares have been traveled
  boolean traversed = true;
  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[0].length; j++) {
      if (grid[i][j].get("traveled") != 1) {
        traversed = false;
        break;
      }
    }
  }
  if (!traversed) {
    ArrayList<JSONObject> activeCubes = getActiveCubes(cubes);
    for (int i = 0; i < activeCubes.size(); ++i) {
      int iter = activeCubes.get(i).getInt("id");
      JSONObject gridPosition = getGridPos(cubes[iter].x, cubes[iter].y);
      // FLOW: - if (toio is stopped)
      if (cubes[iter].detect) {
        int objIter = -1;
        for(int j = 0; j < objects.size(); j++) {
          if(objects.get(j).id == cubes[iter].detectionObjectId) {
            objIter = j;
            break;
          }
        }
        Object obj = objects.get(objIter);
        if (cubes[iter].track) { cubes[iter].track = false; }
        if(cubes[iter].detectionState == DetectionStates.get("Backup")) {
          if (cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety) < 14) {
            // FLOW: Turn position perpendicular 90 degrees by setting target position
            shift(iter);
            cubes[iter].detectionState = DetectionStates.get("Shift");
          }
        } else if(cubes[iter].detectionState == DetectionStates.get("Shift")) {
          if (cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety) < 14) {
            // FLOW: Set target position to grid position in front of where collision happen (from saved target grid position)
            probe(iter);
            cubes[iter].detectionState = DetectionStates.get("Probe");
          }
        } else if(cubes[iter].detectionState == DetectionStates.get("Probe")) {
          // FLOW: Check if toio cannot reach its position by checking if collision is nearby
          boolean collisionNearby = false;
          for(int j = 0; j < obj.collisions.size(); j++) {
            if(cubes[iter].distance(obj.collisions.get(j).x, obj.collisions.get(j).y) < 14) {
              collisionNearby = true;
              break;
            }
          }
          if (collisionNearby) {
            // FLOW: Check if back in starting grid position, if so -> send to next place closest to where it needed to go (save original path target)
            if(gridPosition.getInt("x") == cubes[iter].detectionObjectStartingGridPosX && gridPosition.getInt("y") == cubes[iter].detectionObjectStartingGridPosY) {
              // FLOW: Collision detection done, send to next spot
              cubes[iter].detect = false;
            }
            // FLOW: Backup position linearly
            backup(iter);
            cubes[iter].detectionState = DetectionStates.get("Backup");
          }
        }
      } else {
        println("dd: " + cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety));
        if (cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety) < 14) {
          // FLOW: Set track equal to if not done so already
          if (!cubes[iter].track) { cubes[iter].track = true; }
          // FLOW: if (destination reached)
          int maxBound = (i + 1) * floor(grid.length / activeCubes.size());
          int minBound = i * floor(grid.length / activeCubes.size());
          JSONObject targetPositionFromGrid = new JSONObject();
          targetPositionFromGrid.setInt("x", -1);
          targetPositionFromGrid.setInt("y", -1);
          // FLOW: Check which line should be taken next and create new targetx and targety based on position
          // FLOW: Convert collisions into grid positions
          boolean collRight = false;
          boolean collLeft = false;
          boolean collUp = false;
          boolean collDown = false;
          // FLOW: Check whether or not target grid position is contained in list of grid positions
          for(int ci = 0; ci < objects.size(); ci++) {
            for(int cj = 0; cj < objects.get(ci).collisions.size(); cj++) {
              JSONObject collisionGridPosition = getGridPos(objects.get(i).collisions.get(cj).x, objects.get(i).collisions.get(cj).y);
              if(collisionGridPosition.getInt("x") == gridPosition.getInt("x") + 1 && collisionGridPosition.getInt("y") == gridPosition.getInt("y") ) {
                collRight = true;
                continue;
              } else if(collisionGridPosition.getInt("x") == gridPosition.getInt("x") - 1 && collisionGridPosition.getInt("y") == gridPosition.getInt("y")) {
                collLeft = true;
                continue;
              } else if(collisionGridPosition.getInt("x") == gridPosition.getInt("x") && collisionGridPosition.getInt("y") == gridPosition.getInt("y") - 1) {
                collDown = true;
                continue;
              } else if(collisionGridPosition.getInt("x") == gridPosition.getInt("x") && collisionGridPosition.getInt("y") == gridPosition.getInt("y") + 1) {
                collUp = true;
                continue;
              }
            }
          }
          if(!collRight && gridPosition.getInt("x") + 1 < maxBound && grid[gridPosition.getInt("x") + 1][gridPosition.getInt("y")].get("traveled") != 1) {
            targetPositionFromGrid = getTargetPosition(gridPosition, 'x', 1, maxBound, minBound);
            cubes[iter].direction = Directions.get("Right");
          } else if(!collLeft && gridPosition.getInt("x") - 1 >= minBound && grid[gridPosition.getInt("x") - 1][gridPosition.getInt("y")].get("traveled") != 1) {
            targetPositionFromGrid = getTargetPosition(gridPosition, 'x', -1, maxBound, minBound);
            cubes[iter].direction = Directions.get("Left");
          } else if(!collDown && gridPosition.getInt("y") + 1 < grid[0].length && grid[gridPosition.getInt("x")][gridPosition.getInt("y") + 1].get("traveled") != 1) {
            targetPositionFromGrid = getTargetPosition(gridPosition, 'y', 1, maxBound, minBound);
            cubes[iter].direction = Directions.get("Down");
          } else if(!collUp && gridPosition.getInt("y") - 1 >= 0 && grid[gridPosition.getInt("x")][gridPosition.getInt("y") - 1].get("traveled") != 1) {
            targetPositionFromGrid = getTargetPosition(gridPosition, 'y', -1, maxBound, minBound);
            cubes[iter].direction = Directions.get("Up");
          } else {
            for (int iG = minBound; iG < maxBound; iG++) {
              for (int jG = 0; jG < grid[0].length; jG++) {
                if (grid[iG][jG].get("traveled") != 1) {
                  targetPositionFromGrid.setInt("x", iG);
                  targetPositionFromGrid.setInt("y", jG);
                  break;
                }
              }
            }
          }
          if(targetPositionFromGrid.getInt("x") != -1 && targetPositionFromGrid.getInt("y") != -1) {
            JSONObject targetRealPosition = getRealPosition(targetPositionFromGrid.getInt("x"), targetPositionFromGrid.getInt("y"));
            // FLOW: Turn in direction of targetx and targety to make linear path
            float angleToRotate = getAngleToPosition(cubes[iter], targetRealPosition);
            cubes[iter].targetAngle = angleToRotate;
            // FLOW: Set targetx and targety
            int tax = targetRealPosition.getInt("x");
            int tay = targetRealPosition.getInt("y");
            cubes[iter].targetx = tax;
            cubes[iter].targety = tay;
          }
        }
      }
    }
  } else {
    probe = false;
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[0].length; j++) {
        grid[i][j].set("traveled", 0);
      }
    }
  }
}

void backup(int iter) {
  JSONObject detectionObjectTargetPos = getRealPosition(cubes[iter].detectionObjectGridPosX, cubes[iter].detectionObjectGridPosY);
  int x = cubes[iter].x - detectionObjectTargetPos.getInt("x");
  int y = cubes[iter].y - detectionObjectTargetPos.getInt("y");
  cubes[iter].targetx = cubes[iter].x + x;
  cubes[iter].targety = cubes[iter].y + y;
}

void shift(int iter) {
  JSONObject detectionObjectTargetPos = getRealPosition(cubes[iter].detectionObjectGridPosX, cubes[iter].detectionObjectGridPosY);
  float dx = (cubes[iter].x - detectionObjectTargetPos.getInt("x")) * 1.0;
  float dy = (cubes[iter].y - detectionObjectTargetPos.getInt("y")) * 1.0;
  float r = sqrt((dx*dx) + (dy*dy));
  // FLOW: Angle calculations
  float theta = atan(dy/dx);
  float beta = 180 - 67.5 - theta;
  // FLOW: Distance calculations
  float d = 2*(r*sin(22.5));
  float x = d*cos(beta);
  float y = d*sin(beta);
  cubes[iter].targetx = cubes[iter].x + (int)x;
  cubes[iter].targety = cubes[iter].y + (int)y;
}

void probe(int iter) {
  JSONObject targetPosition = getRealPosition(cubes[iter].detectionObjectGridPosX, cubes[iter].detectionObjectGridPosY);
  cubes[iter].targetx = targetPosition.getInt("x");
  cubes[iter].targety = targetPosition.getInt("y");
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

JSONObject getGridPos(int x, int y) {
  int gridX = floor((x - (MAT_STARTING_POS + (CUBE_SIZE / 2))) / SQUARE_WIDTH);
  int gridY = floor((y - (MAT_STARTING_POS + (CUBE_SIZE / 2))) / SQUARE_HEIGHT);
  if(gridX < 0) { gridX = 0; }
  if(gridY < 0) { gridY = 0; }
  if(gridX > grid.length - 1) { gridX = grid.length - 1; }
  if(gridY > grid[0].length - 1) { gridY = grid[0].length - 1; }
  // FLOW: Instantiate return object
  JSONObject gridPosition = new JSONObject();
  gridPosition.setInt("x", gridX);
  gridPosition.setInt("y", gridY);
  return gridPosition;
}

JSONObject getRealPosition(int x, int y) {
  JSONObject realPosition = new JSONObject();
  realPosition.setInt("x", (MAT_STARTING_POS + (CUBE_SIZE / 2)) + ((x * SQUARE_WIDTH) + (SQUARE_WIDTH / 2)));
  realPosition.setInt("y", (MAT_STARTING_POS + (CUBE_SIZE / 2)) +  ((y * SQUARE_HEIGHT) + (SQUARE_HEIGHT / 2)));
  return realPosition;
}

// FLOW: Get angle to move towards destinations
float getAngleToPosition(Cube cube, JSONObject pos) {
  float xDis = (cube.x - pos.getInt("x")) * 1.0;
  float yDis = (cube.y - pos.getInt("y")) * 1.0;
  float arctan = atan(yDis/xDis) * (180/PI);
  println("Arctan: " + arctan);
  float angle = 0;
  if(xDis < 0 && yDis >= 0) { // 4th quandrant
    println("FOURTH QUAD");
    angle = 270 + (arctan + 90);
  } else if(xDis >= 0 && yDis >= 0) { // 3rd quadrant
    println("THIRD QUAD");
    angle = 270 - (90 - arctan);
  } else if(xDis >= 0 && yDis < 0) { // 2nd quandrant
    println("SECOND QUAD");
    angle = 180 + arctan;
  } else { // 1st quadrant
    println("FIRST QUAD");
    angle = arctan;
  }
  println("Angle: " + angle);
  return angle;
}

JSONObject getTargetPosition(JSONObject startingPos, char axis, int direction, int max, int min) {
  int bound = max - 1;
  int coordinate = startingPos.getInt("x");
  if (direction == -1) { bound = min; }
  if (axis == 'y') {
    bound = grid[0].length - 1;
    coordinate = startingPos.getInt("y");
    if (direction == -1) { bound = 0; }
  }
  JSONObject targetPosition = new JSONObject();
  // FLOW: Loop through rest of mat until a grid is taken
  for(int i = direction; i * direction <= (bound - coordinate) * direction; i += direction) {
    int traveled = 0;
    if (axis == 'x') {
      traveled = grid[startingPos.getInt("x") + i][startingPos.getInt("y")].get("traveled");
    } else {
      traveled = grid[startingPos.getInt("x")][startingPos.getInt("y") + i].get("traveled");
    }
    // FLOW: Set target position to the grid space right before the taken one
    if (axis == 'x') {
      if(traveled == 1) {
        targetPosition.setInt("x", startingPos.getInt("x") + (i - direction));
        targetPosition.setInt("y", startingPos.getInt("y"));
        break;
      } else if (i == (bound - coordinate)) {
        targetPosition.setInt("x", startingPos.getInt("x") + i);
        targetPosition.setInt("y", startingPos.getInt("y"));
        break;
      }
    } else {
      if(traveled == 1) {
        targetPosition.setInt("x", startingPos.getInt("x"));
        targetPosition.setInt("y", startingPos.getInt("y") + (i - direction));
        break;
      } else if(i == (bound - coordinate)) {
        targetPosition.setInt("x", startingPos.getInt("x"));
        targetPosition.setInt("y", startingPos.getInt("y") + i);
        break;
      }
    }
  }
  return targetPosition;
}

void setGridTraveled(int x, int y) {
  JSONObject gridPosition = getGridPos(x, y);
  if(((gridPosition.getInt("x") >= 0 && gridPosition.getInt("x") < grid.length) && (gridPosition.getInt("y") >= 0 && gridPosition.getInt("y") < grid[0].length)) && grid[gridPosition.getInt("x")][gridPosition.getInt("y")].get("traveled") != 1) {
    grid[gridPosition.getInt("x")][gridPosition.getInt("y")].set("traveled", 1);
  }
}
