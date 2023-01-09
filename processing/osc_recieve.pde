int degreeTime = millis();
int positionTime = millis();

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/position") == true) {
    int hostId = msg.get(0).intValue();
    int id = msg.get(1).intValue();
    //int matId = msg.get(1).intValue();
    int posx = msg.get(2).intValue();
    int posy = msg.get(3).intValue();

    int degrees = msg.get(4).intValue();
    // println("Host "+ hostId +" id " + id+" "+posx +" " +posy +" "+degrees);

    id = cubesPerHost * hostId + id;

    if (id < cubes.length) {
      cubes[id].count++;

      float elapsedTime = System.currentTimeMillis() -  cubes[id].lastUpdate ;
      cubes[id].speedX = 1000.0 * float(cubes[id].x - cubes[id].prex) / elapsedTime;
      cubes[id].speedY = 1000.0 * float(cubes[id].y - cubes[id].prey) / elapsedTime;

      cubes[id].prex = cubes[id].x;
      cubes[id].prey = cubes[id].y;

      cubes[id].x = posx;
      cubes[id].y = posy;

      if(!positionTimer) {
        startPositionTimer();
      } else if(millis() - positionTime >= POSITION_TIMER_LIMIT) {
        cubes[id].timeoutx = cubes[id].x;
        cubes[id].timeouty = cubes[id].y;
        stopPositionTimer();
      }

      if(!degreeTimer) {
        startDegreeTimer();
      } else if(millis() - degreeTime >= DEGREE_TIMER_LIMIT) {
        cubes[id].preDeg = cubes[id].deg;
        stopDegreeTimer();
      }

      cubes[id].deg = degrees;

      cubes[id].lastUpdate = System.currentTimeMillis();

      float sumX = 0, sumY = 0;
      for (int j = 0; j < cubes[id].aveFrameNum - 1; j++) {
        cubes[id].pre_speedX[cubes[id].aveFrameNum -1 - j] = cubes[id].pre_speedX[cubes[id].aveFrameNum -j -2];
        cubes[id].pre_speedY[cubes[id].aveFrameNum -1 - j] = cubes[id].pre_speedY[cubes[id].aveFrameNum -j -2];
        sumX += cubes[id].pre_speedX[cubes[id].aveFrameNum -1 - j];
        sumY += cubes[id].pre_speedY[cubes[id].aveFrameNum -1 - j];
      }

      sumX +=  cubes[id].speedX;
      sumY +=  cubes[id].speedY;

      cubes[id].pre_speedX[0] = cubes[id].speedX;
      cubes[id].pre_speedY[0] = cubes[id].speedY;

      //println(cubes[id].speedX, cubes[id].speedY);

      cubes[id].ave_speedX = sumX / float(cubes[id].aveFrameNum);
      cubes[id].ave_speedY = sumY / float(cubes[id].aveFrameNum);

      //println(cubes[id].ave_speedX, cubes[id].ave_speedY);
      if (cubes[id].isLost == true) {
        cubes[id].isLost = false;
      }
    }
  } else if (msg.checkAddrPattern("/button") == true) {
    int hostId = msg.get(0).intValue();
    int relid = msg.get(1).intValue();
    int id = cubesPerHost*hostId + relid;
    int pressValue = msg.get(2).intValue();
    //println("Button pressed for id : "+id + " "+ pressValue);
  } else if (msg.checkAddrPattern("/motion") == true) {
    int hostId = msg.get(0).intValue();
    int relid = msg.get(1).intValue();
    int id = cubesPerHost * hostId + relid;
    int flatness = msg.get(2).intValue();
    int hit = msg.get(3).intValue();
    println(hit);
    // FLOW: Determine collision detection and position
    // if(hit == 1) {
    //   int objectId = objects.size();
    //   Object obj = new Object(objectId);
    //   if (!cubes[id].detect) {
    //     // FLOW: Set collision detection on cube to true
    //     cubes[id].detect = true;
    //     cubes[id].detectionObjectId = objectId;
    //     // FLOW: Set grid position
    //     JSONObject gridPosition = getGridPos(cubes[id].x, cubes[id].y);
    //     cubes[id].detectionObjectStartingGridPosX = gridPosition.getInt("x");
    //     cubes[id].detectionObjectStartingGridPosY = gridPosition.getInt("y");
    //     // FLOW: Run probe target position calculation code here
    //     JSONObject targetPosition = new JSONObject();
    //     // FLOW: Move toio is opposite direction (1 CUBE_LENGTHS)
    //     // FLOW: Find which way target grid is positioned (save this from target pos calculation)
    //     switch (cubes[id].direction) {
    //       case 3:
    //         if(gridPosition.getInt("x") < grid.length) {
    //           cubes[id].detectionObjectGridPosX = gridPosition.getInt("x") + 1;
    //         } else {
    //           cubes[id].detectionObjectGridPosX = gridPosition.getInt("x");
    //         }
    //         cubes[id].detectionObjectGridPosY = gridPosition.getInt("y");
    //         targetPosition = getRealPosition(gridPosition.getInt("x") - 1, gridPosition.getInt("y"));
    //         break;
    //       case 2:
    //         if(gridPosition.getInt("x") > 0) {
    //           cubes[id].detectionObjectGridPosX = gridPosition.getInt("x") - 1;
    //         } else {
    //           cubes[id].detectionObjectGridPosX = gridPosition.getInt("x");
    //         }
    //         cubes[id].detectionObjectGridPosY = gridPosition.getInt("y");
    //         targetPosition = getRealPosition(gridPosition.getInt("x") + 1, gridPosition.getInt("y"));
    //         break;
    //       case 0:
    //         if(gridPosition.getInt("y") > 0) {
    //           cubes[id].detectionObjectGridPosY = gridPosition.getInt("y") - 1;
    //         } else {
    //           cubes[id].detectionObjectGridPosY = gridPosition.getInt("y");
    //         }
    //         cubes[id].detectionObjectGridPosX = gridPosition.getInt("x");
    //         targetPosition = getRealPosition(gridPosition.getInt("x"), gridPosition.getInt("y") + 1);
    //         break;
    //       case 1:
    //         if(gridPosition.getInt("y") < grid[0].length) {
    //           cubes[id].detectionObjectGridPosY = gridPosition.getInt("y") + 1;
    //         } else {
    //           cubes[id].detectionObjectGridPosY = gridPosition.getInt("y");
    //         }
    //         cubes[id].detectionObjectGridPosX = gridPosition.getInt("x");
    //         targetPosition = getRealPosition(gridPosition.getInt("x"), gridPosition.getInt("y") - 1);
    //         break;
    //       default:
    //         cubes[id].detectionObjectGridPosX = gridPosition.getInt("x");
    //         cubes[id].detectionObjectGridPosY = gridPosition.getInt("y");
    //         targetPosition = getRealPosition(gridPosition.getInt("x"), gridPosition.getInt("y"));
    //         break;
    //     }
    //     cubes[id].targetx = targetPosition.getInt("x");
    //     cubes[id].targety = targetPosition.getInt("y");
    //     // FLOW: Set state to Backup
    //     cubes[id].detectionState = DetectStates.get("Backup");
    //   } else {
    //     objectId = cubes[id].detectionObjectId;
    //     for(int i = 0; i < objects.size(); i++) {
    //       if(objects.get(i).id == objectId) {
    //         obj = objects.get(i);
    //         break;
    //       }
    //     }
    //   }
    //   // FLOW: Save collision
    //   Collision collision = new Collision(obj.collisions.size(), objectId, cubes[id].x, cubes[id].y, cubes[id].deg);
    //   obj.collisions.add(collision);
    //   objects.add(obj);
    // }
    int double_tap = msg.get(4).intValue();
    int face_up = msg.get(5).intValue();
    int shake_level = msg.get(6).intValue();
    println("motion for id " + id + ": " + flatness + ", " + hit + ", " + double_tap + ", " + face_up + ", " + shake_level);
  }
}

void startPositionTimer() {
  positionTime = millis();
  positionTimer = true;
}

void stopPositionTimer() {
  positionTimer = false;
}

void startDegreeTimer() {
  degreeTime = millis();
  degreeTimer = true;
}

void stopDegreeTimer() {
  degreeTimer = false;
}
