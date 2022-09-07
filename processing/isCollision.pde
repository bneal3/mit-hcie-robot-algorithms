int time = millis();

void isCollision(int iter, GridPosition gridPosition) {
  // FLOW: Start timer
  if(!timer) {
    startTimer();
  } else if(millis() - time >= COLLISION_TIMER_LIMIT) {
    int objIter = -1;
    int collisions = 0;
    int objectId = objects.size();
    // FLOW: If already detecting, get objIter collision count from saved object
    for(int i = 0; i < objects.size(); i++) {
      if(objects.get(i).id == cubes[iter].detectObjectId) {
        objIter = i;
        collisions = objects.get(i).collisions.size();
        objectId = cubes[iter].detectObjectId;
        break;
      }
    }
    // FLOW: Save collision
    Collision collision = new Collision(collisions, objectId, cubes[iter].x, cubes[iter].y, cubes[iter].deg);
    // FLOW: Check if object in detect mode
    if(!cubes[iter].detect) {
      println("Detecting...");
      // FLOW: Set collision detection on cube to true
      cubes[iter].detect = true;
      // FLOW: Set detect object id and add to objects array list
      Object obj = new Object(objectId);
      cubes[iter].detectObjectId = obj.id;
      obj.collisions.add(collision);
      objects.add(obj);
      // FLOW: Set starting grid position
      cubes[iter].detectStartingGridPosition = gridPosition;
      // FLOW: Run probe target position calculation code here
      // FLOW: Move toio is opposite direction (1 CUBE_LENGTHS)
      // FLOW: Find which way target grid is positioned (save this from target pos calculation)
      GridPosition targetGridPositionFromState = new GridPosition(-1, -1);
      switch(cubes[iter].direction) {
        case 3:
          if(gridPosition.x < grid.length) {
            cubes[iter].detectObjectGridPosition.x = gridPosition.x + 1;
          } else {
            cubes[iter].detectObjectGridPosition.x = gridPosition.x;
          }
          cubes[iter].detectObjectGridPosition.y = gridPosition.y;
          targetGridPositionFromState = new GridPosition(gridPosition.x - 1, gridPosition.y);
          break;
        case 2:
          if(gridPosition.x > 0) {
            cubes[iter].detectObjectGridPosition.x = gridPosition.x - 1;
          } else {
            cubes[iter].detectObjectGridPosition.x = gridPosition.x;
          }
          cubes[iter].detectObjectGridPosition.y = gridPosition.y;
          targetGridPositionFromState = new GridPosition(gridPosition.x + 1, gridPosition.y);
          break;
        case 0:
          if(gridPosition.y > 0) {
            cubes[iter].detectObjectGridPosition.y = gridPosition.y - 1;
          } else {
            cubes[iter].detectObjectGridPosition.y = gridPosition.y;
          }
          cubes[iter].detectObjectGridPosition.x = gridPosition.x;
          targetGridPositionFromState = new GridPosition(gridPosition.x, gridPosition.y + 1);
          break;
        case 1:
          if(gridPosition.y < grid[0].length) {
            cubes[iter].detectObjectGridPosition.y = gridPosition.y + 1;
          } else {
            cubes[iter].detectObjectGridPosition.y = gridPosition.y;
          }
          cubes[iter].detectObjectGridPosition.x = gridPosition.x;
          targetGridPositionFromState = new GridPosition(gridPosition.x, gridPosition.y - 1);
          break;
        default:
          cubes[iter].detectObjectGridPosition = gridPosition;
          targetGridPositionFromState = gridPosition;
          break;
      }
      cubes[iter].targetx = targetGridPositionFromState.xCoordinate(targetGridPositionFromState);
      cubes[iter].targety = targetGridPositionFromState.yCoordinate(targetGridPositionFromState);
      // FLOW: Set state to Backup
      cubes[iter].detectState = DetectStates.get("Backup");
    } else {
      // FLOW: If already detecting, push to collisions if not already there
      boolean contains = false;
      for(int i = 0; i < objects.get(objIter).collisions.size(); i++) {
        if(objects.get(objIter).collisions.get(i).x == cubes[iter].x && objects.get(objIter).collisions.get(i).y == cubes[iter].y) {
          contains = true;
          break;
        }
      }
      if(!contains) { objects.get(objIter).collisions.add(collision); }
    }
    stopTimer();
  }
}

void startTimer() {
  time = millis();
  timer = true;
}

void stopTimer() {
  timer = false;
}
