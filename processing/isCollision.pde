int collisionTime = millis();

void isCollision(int iter, GridPosition gridPosition) {
  // FLOW: Start timer
  if(!collisionTimer) {
    startCollisionTimer();
  } else if(millis() - collisionTime >= COLLISION_TIMER_LIMIT) {
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
      // FLOW: Set state to Backup
      backup(iter);
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
    stopCollisionTimer();
  }
}

void startCollisionTimer() {
  collisionTime = millis();
  collisionTimer = true;
}

void stopCollisionTimer() {
  collisionTimer = false;
}
