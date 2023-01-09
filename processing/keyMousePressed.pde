void keyPressed() {
  ArrayList<JSONObject> activeCubes = getActiveCubes(cubes);
  switch(key) {
  case 'f':
    try {
      midi(0, 64, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 63, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 64, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 63, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 64, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 63, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 59, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 62, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 60, 255, 10);
      java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
      midi(0, 57, 255, 10);

    } catch(InterruptedException e) {
      System.out.println("got interrupted!");
    }
    break;

  case '`':
    midi(0, 57, 255, 10);
    break;

  case '1':
    midi(0, 58, 255, 10);
    break;

  case '2':
    midi(0, 59, 255, 10);
    break;

  case '3':
    midi(0, 60, 255, 10);
    break;

  case '4':
    midi(0, 61, 255, 10);
    break;

  case '5':
    midi(0, 62, 255, 10);
    break;

  case '6':
    midi(0, 63, 255, 10);
    break;

  case '7':
    midi(0, 64, 255, 10);
    break;

  case '8':
    midi(0, 65, 255, 10);
    break;

  case '9':
    midi(0, 66, 255, 10);
    break;

  case '0':
    midi(0, 67, 255, 10);
    break;

  case '-':
    midi(0, 68, 255, 10);
    break;

  case 'd':
    chase = false;
    spin = false;
    mouseDrive = false;
    break;

  case 'a':
    for (int i=0; i < nCubes; ++i) {
      aimMotorControl(i, 380, 260);
    }
    break;

  case 'k':
    light(0, 100, 255, 0, 0);
    break;

  case 'm':
    motion(0);
    break;

  case 'p':
    println("Probing...");
    // FLOW: Split toios based on how many there for start positions
    for (int i = 0; i < activeCubes.size(); i++) {
      int iter = activeCubes.get(i).getInt("id");
      int x = i * floor(grid.length / activeCubes.size());
      GridPosition targetGridPosition = grid[x][8];
      float angleToRotate = getAngleToTargetPosition(cubes[iter], new Position(targetGridPosition.xCoordinate(targetGridPosition), targetGridPosition.yCoordinate(targetGridPosition)));
      cubes[iter].targetAngle = angleToRotate;
      cubes[iter].targetx = targetGridPosition.xCoordinate(targetGridPosition);
      cubes[iter].targety = targetGridPosition.yCoordinate(targetGridPosition);
    }
    probe = true;
    break;

  case 't':
    println("Transporting...");
    // FLOW: Mock parameters
    int objectId = 0;
    int direction = Directions.get("Right");
    // FLOW: Caclulate center of mass of object
    int comx = 0;
    int comy = 0;
    for (int i = 0; i < objects.get(objectId).collisions.size(); i++) {
      comx += objects.get(objectId).collisions.get(i).x;
      comy += objects.get(objectId).collisions.get(i).y;
    }
    objects.get(objectId).centerX = comx / objects.get(objectId).collisions.size();
    objects.get(objectId).centerY = comy / objects.get(objectId).collisions.size();
    // FLOW: Split object by amount of toios and find position points (create array of Positions based on how many toios)
    int baselineCoordinate = -1;
    int maxCoordinate = -1;
    int minCoordinate = -1;
    if(direction == Directions.get("Right")) {
      baselineCoordinate = objects.get(objectId).collisions.get(0).x;
      maxCoordinate = objects.get(objectId).collisions.get(0).y;
      minCoordinate = objects.get(objectId).collisions.get(0).y;
      for (int i = 1; i < objects.get(objectId).collisions.size(); i++) {
        // FLOW: Get new baseline coordinate
        if(objects.get(objectId).collisions.get(i).x < baselineCoordinate) {
          baselineCoordinate = objects.get(objectId).collisions.get(i).x;
        }
        // FLOW: Get new object max and min coordinates
        if(objects.get(objectId).collisions.get(i).y > maxCoordinate) {
          maxCoordinate = objects.get(objectId).collisions.get(i).y;
        }
        if(objects.get(objectId).collisions.get(i).y < minCoordinate) {
          minCoordinate = objects.get(objectId).collisions.get(i).y;
        }
      }
    }
    // FLOW: Send toios to calculated starting points (w/ offset) by direction of push
    Position[] startingPositions = new Position[activeCubes.size()];
    float difference = maxCoordinate - minCoordinate;
    if(direction == Directions.get("Right")) {
      for(int i = 0; i < activeCubes.size(); i++) {
        int iter = activeCubes.get(i).getInt("id");
        float active = (activeCubes.size() + 1.0) * 1.0;
        float ratio = (((i * 1.0) + 1.0) / active) * 1.0;
        float delta = ratio * difference;
        startingPositions[i] = new Position(baselineCoordinate - TRANSPORT_STARTING_OFFSET, minCoordinate + (int)(delta));
        cubes[iter].targetx = startingPositions[i].x;
        cubes[iter].targety = startingPositions[i].y;
        cubes[iter].transportState = TransportStates.get("Position");
      }
    }
    transport = true;
    break;

  case 'q':
    println("Quiting...");
    // FLOW: Stop functions
    probe = false;
    transport = false;
    // FLOW: Stop all timers
    stopCollisionTimer();
    stopBackupTimer();
    stopShiftTimer();
    stopAttackTimer();
    stopLostTimer();
    // FLOW: Reset all toio function variables
    for(int i = 0; i < nCubes; i++) {
      cubes[i].track = false;
      cubes[i].direction = -1;
      // FLOW: Detect variables
      cubes[i].detect = false;
      cubes[i].detectState = -1;
      cubes[i].detectObjectId = -1;
      cubes[i].detectStartingGridPosition = new GridPosition(-1, -1);
      cubes[i].detectMotorControl[0] = 0;
      cubes[i].detectMotorControl[1] = 0;
      // FLOW: Transport variables
      cubes[i].transportState = -1;
      cubes[i].transportPosition = new Position(-1, -1);
      cubes[i].transportMotorControl[0] = 0;
      cubes[i].transportMotorControl[1] = 0;
      motorControl(i, 0, 0, (0));
    }
    break;

  default:
    break;

  }
}

void mousePressed() {
  chase = false;
  spin = false;
  mouseDrive=true;
}

void mouseReleased() {
  mouseDrive=false;
}
