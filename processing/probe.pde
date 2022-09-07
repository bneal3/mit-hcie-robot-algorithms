// FUNCTION: Probe
void probe() {
  // FLOW: Check if all grid positions have been probed
  boolean boardProbed = true;
  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[0].length; j++) {
      if (!grid[i][j].traveled) {
        boardProbed = false;
        break;
      }
    }
  }
  if(!boardProbed) {
    ArrayList<JSONObject> activeCubes = getActiveCubes(cubes);
    for (int i = 0; i < activeCubes.size(); i++) {
      // FLOW: Necessary Variables for calculations
      int iter = activeCubes.get(i).getInt("id");
      GridPosition gridPosition = getGridPosition(cubes[iter].x, cubes[iter].y);
      float distanceFromTarget = cubes[iter].distance(cubes[iter].targetx, cubes[iter].targety);
      println("Deg difference: " + floor(abs(cubes[i].deg - cubes[i].preDeg)));
      // FLOW: Collision detected
      if(distanceFromTarget > 14 && abs(cubes[i].x - cubes[i].prex) <= 1 && abs(cubes[i].y - cubes[i].prey) <= 1 && floor(abs(cubes[i].deg - cubes[i].preDeg)) < 1) {
        isCollision(iter, gridPosition);
      } else {
        stopTimer();
      }
      // FLOW: Run detection algorithm
      if(cubes[iter].detect) {
        detect(iter, gridPosition, distanceFromTarget);
      } else {
        // FLOW: Run probe algorithm
        if(distanceFromTarget < 14) { // FLOW: if (destination reached)
          setTargetPositionFromPath(iter, gridPosition, i, activeCubes.size());
        }
      }
    }
  } else {
    // FLOW: Reset variables
    probe = false;
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[0].length; j++) {
        grid[i][j].traveled = false;
      }
    }
  }
}

void setTargetPositionFromPath(int iter, GridPosition gridPosition, int currentCubeIter, int numActiveCubes) {
  // FLOW: Set track equal to true if not done so already
  if (!cubes[iter].track) { cubes[iter].track = true; }
  // FLOW: Check which line should be taken next and create new targetx and targety based on chosen pathway
  int maxBound = (currentCubeIter + 1) * floor(grid.length / numActiveCubes);
  int minBound = currentCubeIter * floor(grid.length / numActiveCubes);
  GridPosition targetGridPositionFromPath = new GridPosition(-1, -1);
  // FLOW: Convert collisions into grid positions
  boolean collRight = false;
  boolean collLeft = false;
  boolean collUp = false;
  boolean collDown = false;
  // FLOW: Check whether or not target grid position is contained in list of grid positions
  for(int i = 0; i < objects.size(); i++) {
    for(int j = 0; j < objects.get(i).collisions.size(); j++) {
      GridPosition collisionGridPosition = getGridPosition(objects.get(i).collisions.get(j).x, objects.get(i).collisions.get(j).y);
      if(collisionGridPosition.x == gridPosition.x + 1 && collisionGridPosition.y == gridPosition.y) {
        collRight = true;
        continue;
      } else if(collisionGridPosition.x == gridPosition.x - 1 && collisionGridPosition.y == gridPosition.y) {
        collLeft = true;
        continue;
      } else if(collisionGridPosition.x == gridPosition.x && collisionGridPosition.y == gridPosition.y - 1) {
        collDown = true;
        continue;
      } else if(collisionGridPosition.x == gridPosition.x && collisionGridPosition.y == gridPosition.y + 1) {
        collUp = true;
        continue;
      }
    }
  }
  // println("R " + collRight);
  // println("L " + collLeft);
  // println("U " + collUp);
  // println("D " + collDown);
  if(!collRight && gridPosition.x + 1 < maxBound && !gridPosition.traveled) {
    targetGridPositionFromPath = getTargetGridPositionFromPath(gridPosition, 'x', 1, maxBound, minBound);
    cubes[iter].direction = Directions.get("Right");
  } else if(!collLeft && gridPosition.x - 1 >= minBound && !gridPosition.traveled) {
    targetGridPositionFromPath = getTargetGridPositionFromPath(gridPosition, 'x', -1, maxBound, minBound);
    cubes[iter].direction = Directions.get("Left");
  } else if(!collDown && gridPosition.y + 1 < grid[0].length && !gridPosition.traveled) {
    targetGridPositionFromPath = getTargetGridPositionFromPath(gridPosition, 'y', 1, maxBound, minBound);
    cubes[iter].direction = Directions.get("Down");
  } else if(!collUp && gridPosition.y - 1 >= 0 && !gridPosition.traveled) {
    targetGridPositionFromPath = getTargetGridPositionFromPath(gridPosition, 'y', -1, maxBound, minBound);
    cubes[iter].direction = Directions.get("Up");
  } else {
    // FLOW: Set targetGridPositionFromPath to any grid position that has not been traveled to yet
    for (int i = minBound; i < maxBound; i++) {
      for (int j = 0; j < grid[0].length; j++) {
        if (!grid[i][j].traveled) {
          targetGridPositionFromPath.x = i;
          targetGridPositionFromPath.y = j;
          break;
        }
      }
    }
  }
  // FLOW: Check to make sure a targetGridPosition was set
  if(targetGridPositionFromPath.x != -1 && targetGridPositionFromPath.y != -1) {
    // FLOW: Turn in direction of targetx and targety to make linear path
    float angleToRotate = getAngleToTargetPosition(cubes[iter], new Position(targetGridPositionFromPath.xCoordinate(targetGridPositionFromPath), targetGridPositionFromPath.yCoordinate(targetGridPositionFromPath)));
    cubes[iter].targetAngle = angleToRotate;
    // FLOW: Set targetx and targety
    cubes[iter].targetx = targetGridPositionFromPath.xCoordinate(targetGridPositionFromPath);
    cubes[iter].targety = targetGridPositionFromPath.yCoordinate(targetGridPositionFromPath);
  }
}

GridPosition getTargetGridPositionFromPath(GridPosition startingGridPosition, char axis, int direction, int max, int min) {
  int bound = max - 1;
  int coordinate = startingGridPosition.x;
  if (direction == -1) { bound = min; }
  if (axis == 'y') {
    bound = grid[0].length - 1;
    coordinate = startingGridPosition.y;
    if (direction == -1) { bound = 0; }
  }
  GridPosition targetGridPosition = new GridPosition(-1, -1);
  // FLOW: Loop through rest of board until a grid space is taken
  for(int i = direction; i * direction <= (bound - coordinate) * direction; i += direction) {
    boolean traveled = false;
    if (axis == 'x') {
      traveled = grid[startingGridPosition.x + i][startingGridPosition.y].traveled;
    } else {
      traveled = grid[startingGridPosition.x][startingGridPosition.y + i].traveled;
    }
    // FLOW: Set target grid position to the grid space right before the taken one
    if(axis == 'x') {
      if(traveled) {
        targetGridPosition.x = startingGridPosition.x + (i - direction);
        targetGridPosition.y = startingGridPosition.y;
        break;
      } else if(i == (bound - coordinate)) {
        targetGridPosition.x = startingGridPosition.x + i;
        targetGridPosition.y = startingGridPosition.y;
        break;
      }
    } else {
      if(traveled) {
        targetGridPosition.x = startingGridPosition.x;
        targetGridPosition.y = startingGridPosition.y + (i - direction);
        break;
      } else if(i == (bound - coordinate)) {
        targetGridPosition.x = startingGridPosition.x;
        targetGridPosition.y = startingGridPosition.y + i;
        break;
      }
    }
  }
  return targetGridPosition;
}
