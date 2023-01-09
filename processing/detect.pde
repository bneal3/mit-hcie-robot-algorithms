int backupTime = millis();
int shiftTime = millis();
int attackTime = millis();
int lostTime = millis();

void detect(int iter, GridPosition gridPosition, int currentCubeIter, int numActiveCubes) {
  // FLOW: Find object iterator
  int objIter = -1;
  for(int i = 0; i < objects.size(); i++) {
    if(objects.get(i).id == cubes[iter].detectObjectId) {
      objIter = i;
      break;
    }
  }
  // FLOW: Turn tracking off while detecting
  if (cubes[iter].track) { cubes[iter].track = false; }
  // FLOW: calculate variables used for calculations later
  float da = abs(cubes[iter].deg - cubes[iter].targetAngle);
  float daOverflow = abs(cubes[iter].deg - (cubes[iter].targetAngle + 360));
  // FLOW: Check completion criteria based on state
  if(cubes[iter].detectState == DetectStates.get("Backup")) {
    // FLOW: Do timer calculation for stop
    if(!backupTimer) {
      startBackupTimer();
    } else if(millis() - backupTime >= BACKUP_TIMER_LIMIT) {
      // FLOW: Set target position to previously calculated position
      shift(iter);
      cubes[iter].detectState = DetectStates.get("Shift");
      stopBackupTimer();
    }
  } else if(cubes[iter].detectState == DetectStates.get("Shift")) {
    // FLOW: Do timer calculation for stop
    if(!shiftTimer) {
      // FLOW: Check for if angle is met
      if(da <= 7 || daOverflow <= 7) { startShiftTimer(); }
    } else if(millis() - shiftTime >= SHIFT_TIMER_LIMIT) {
      // FLOW: Set target position to previously calculated position
      attack(iter);
      cubes[iter].detectState = DetectStates.get("Attack");
      stopShiftTimer();
    }
  } else if(cubes[iter].detectState == DetectStates.get("Attack") || cubes[iter].detectState == DetectStates.get("Lost")) {
    // FLOW: Check if toio cannot reach its position by checking if collision is nearby
    boolean isNextToCollision = false;
    boolean isNextToFirstCollision = false;
    for(int i = 0; i < objects.get(objIter).collisions.size(); i++) {
      if(cubes[iter].distance(objects.get(objIter).collisions.get(i).x, objects.get(objIter).collisions.get(i).y) < 14) {
        isNextToCollision = true;
        if(i == 0) {
          isNextToFirstCollision = true;
        }
        break;
      }
    }
    if(isNextToCollision) {
      // FLOW: Check if back in starting grid position, if so -> send to next place closest to where it needed to go (save original path target)
      if(isNextToFirstCollision) {
        // FLOW: Collision detection done, send to next spot
        setTargetPositionFromPath(iter, gridPosition, currentCubeIter, numActiveCubes);
        stop(iter);
      } else {
        // FLOW: Set state to backup
        backup(iter);
        cubes[iter].detectState = DetectStates.get("Backup");
      }
      stopAttackTimer();
      stopLostTimer();
    } else {
      if(cubes[iter].detectState == DetectStates.get("Attack")) {
        if(!attackTimer) {
          // FLOW: Check for if angle is met
          if(da <= 7 || daOverflow <= 7) { startAttackTimer(); }
        } else if(millis() - attackTime >= ATTACK_TIMER_LIMIT) {
          // FLOW: Circle back to original spot
          lost(iter);
          cubes[iter].detectState = DetectStates.get("Lost");
          stopAttackTimer();
        }
      } else if(cubes[iter].detectState == DetectStates.get("Lost")) {
        if(!lostTimer) {
          // FLOW: Check for if angle is met
          if(da <= 7 || daOverflow <= 7) { startLostTimer(); }
        } else if(millis() - lostTime >= LOST_TIMER_LIMIT) {
          // FLOW: Set angle to target angle position
          float angleToRotate = getAngleToTargetPosition(cubes[iter], new Position((int)(cubes[iter].targetx), (int)(cubes[iter].targety)));
          cubes[iter].targetAngle = angleToRotate;
          stop(iter);
          stopLostTimer();
        }
      }
    }
  }
}

void backup(int iter) {
  // FLOW: Set motor control
  cubes[iter].detectMotorControl[0] = -50;
  cubes[iter].detectMotorControl[1] = -50;
  // FLOW: Set angle
  cubes[iter].targetAngle = cubes[iter].deg;
}

void shift(int iter) {
  // FLOW: Set motor control
  cubes[iter].detectMotorControl[0] = 50;
  cubes[iter].detectMotorControl[1] = 50;
  // FLOW: Set angle
  float angle = cubes[iter].deg + 90;
  if(angle > 360) { angle = angle - 360; }
  cubes[iter].targetAngle = angle;
}

void attack(int iter) {
  // FLOW: Set motor control
  cubes[iter].detectMotorControl[0] = 40;
  cubes[iter].detectMotorControl[1] = 40;
  // FLOW: Set angle
  float angle = cubes[iter].deg - 90;
  if(angle < 0) { angle = 360 - (-angle); }
  cubes[iter].targetAngle = angle;
}

void lost(int iter) {
  // FLOW: Set motor control
  cubes[iter].detectMotorControl[0] = 40;
  cubes[iter].detectMotorControl[1] = 40;
  // FLOW: Turn in direction of targetx and targety to make linear path
  Position detectStartingPosition = new Position(cubes[iter].detectStartingGridPosition.xCoordinate(cubes[iter].detectStartingGridPosition), cubes[iter].detectStartingGridPosition.yCoordinate(cubes[iter].detectStartingGridPosition));
  float angleToRotate = getAngleToTargetPosition(cubes[iter], detectStartingPosition);
  cubes[iter].targetAngle = angleToRotate;
}

void stop(int iter) {
  // FLOW: Come out of detection mode
  cubes[iter].detect = false;
  cubes[iter].detectState = DetectStates.get("None");
}

void startBackupTimer() {
  backupTime = millis();
  backupTimer = true;
}

void stopBackupTimer() {
  backupTimer = false;
}

void startShiftTimer() {
  shiftTime = millis();
  shiftTimer = true;
}

void stopShiftTimer() {
  shiftTimer = false;
}

void startAttackTimer() {
  attackTime = millis();
  attackTimer = true;
}

void stopAttackTimer() {
  attackTimer = false;
}

void startLostTimer() {
  lostTime = millis();
  lostTimer = true;
}

void stopLostTimer() {
  lostTimer = false;
}
