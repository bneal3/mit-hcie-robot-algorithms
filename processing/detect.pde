void detect(int iter, GridPosition gridPosition, float distanceFromTarget) {
  int objIter = -1;
  for(int i = 0; i < objects.size(); i++) {
    if(objects.get(i).id == cubes[iter].detectObjectId) {
      objIter = i;
      break;
    }
  }
  // FLOW: Turn tracking off while detecting
  if (cubes[iter].track) { cubes[iter].track = false; }
  // println(cubes[iter].detectState);
  // FLOW: Check completion criteria based on state
  if(cubes[iter].detectState == DetectStates.get("Backup")) {
    if (distanceFromTarget < 14) {
      // FLOW: Turn position perpendicular 90 degrees by setting target position
      shift(iter);
      cubes[iter].detectState = DetectStates.get("Shift");
    }
  } else if(cubes[iter].detectState == DetectStates.get("Shift")) {
    if (distanceFromTarget < 14) {
      // FLOW: Set target position to grid position in front of where collision happen (from saved target grid position)
      attack(iter);
      cubes[iter].detectState = DetectStates.get("Attack");
    }
  } else if(cubes[iter].detectState == DetectStates.get("Attack")) {
    // FLOW: Check if toio cannot reach its position by checking if collision is nearby
    boolean isNextToCollision = false;
    for(int i = 0; i < objects.get(objIter).collisions.size(); i++) {
      if(cubes[iter].distance(objects.get(objIter).collisions.get(i).x, objects.get(objIter).collisions.get(i).y) < 14) {
        isNextToCollision = true;
        break;
      }
    }
    if(isNextToCollision) {
      // FLOW: Backup position linearly
      backup(iter);
      // FLOW: Check if back in starting grid position, if so -> send to next place closest to where it needed to go (save original path target)
      if(gridPosition.x == cubes[iter].detectObjectGridPosition.x && gridPosition.y == cubes[iter].detectObjectGridPosition.y) {
        // FLOW: Collision detection done, send to next spot
        cubes[iter].detect = false;
        cubes[iter].detectState = DetectStates.get("None");
      } else {
        cubes[iter].detectState = DetectStates.get("Backup");
      }
    }
  }
}

void backup(int iter) {
  int x = cubes[iter].x - cubes[iter].detectObjectGridPosition.xCoordinate(cubes[iter].detectObjectGridPosition);
  int y = cubes[iter].y - cubes[iter].detectObjectGridPosition.yCoordinate(cubes[iter].detectObjectGridPosition);
  cubes[iter].targetx = cubes[iter].x - x;
  cubes[iter].targety = cubes[iter].y - y;
}

void shift(int iter) {
  float dx = (cubes[iter].x - cubes[iter].detectObjectGridPosition.xCoordinate(cubes[iter].detectObjectGridPosition)) * 1.0;
  float dy = (cubes[iter].y - cubes[iter].detectObjectGridPosition.yCoordinate(cubes[iter].detectObjectGridPosition)) * 1.0;
  float r = sqrt((dx * dx) + (dy * dy));
  // FLOW: Distance calculations
  float d = 2 * (r * sin(30 * (PI / 180)));
  float x = d * sin(30 * (PI / 180));
  float y = d * cos(30 * (PI / 180));
  println("r " + r);
  println("dx " + dx);
  println("dy " + dy);
  // FLOW: Calculate dx2 and dy2 based on quandrant
  int dx2 = -1;
  int dy2 = -1;
  // FLOW: Update dx2 and dy2 by offset quadrant
  if(dx > 0 && dy - (r * sin(30 * (PI / 180))) <= 0) { // 4th quandrant
    println("4th QUANDRANT");
    dx2 = cubes[iter].x - (int)x;
    dy2 = cubes[iter].y - (int)y;
  } else if(dx - (r * sin(30 * (PI / 180))) <= 0 && dy > 0) { // 3rd quadrant
    println("3rd QUANDRANT");
    dx2 = cubes[iter].x - (int)x;
    dy2 = cubes[iter].y + (int)y;
  } else if(dx < 0 && dy + (r * sin(30 * (PI / 180))) >= 0) { // 2nd quandrant
    println("2nd QUANDRANT");
    dx2 = cubes[iter].x + (int)x;
    dy2 = cubes[iter].y + (int)y;
  } else { // 1st quadrant
    println("1st QUANDRANT");
    dx2 = cubes[iter].x + (int)x;
    dy2 = cubes[iter].y - (int)y;
  }
  Position targetPositionFromShift = new Position(dx2, dy2);
  // FLOW: Turn in direction of targetx and targety to make linear path
  float angleToRotate = getAngleToTargetPosition(cubes[iter], targetPositionFromShift);
  cubes[iter].targetAngle = angleToRotate;
  // Set target position
  cubes[iter].targetx = targetPositionFromShift.x;
  cubes[iter].targety = targetPositionFromShift.y;
}

void attack(int iter) {
  Position targetPositionFromAttack = new Position(cubes[iter].detectObjectGridPosition.xCoordinate(cubes[iter].detectObjectGridPosition), cubes[iter].detectObjectGridPosition.yCoordinate(cubes[iter].detectObjectGridPosition));
  // FLOW: Turn in direction of targetx and targety to make linear path
  float angleToRotate = getAngleToTargetPosition(cubes[iter], targetPositionFromAttack);
  cubes[iter].targetAngle = angleToRotate;
  // Set target position
  cubes[iter].targetx = targetPositionFromAttack.x;
  cubes[iter].targety = targetPositionFromAttack.y;
}
