class Cube {
  int count = 0;
  // FLOW: Position Members
  int x;
  int y;
  int prex;
  int prey;
  float speedX;
  float speedY;
  float targetx = -1;
  float targety = -1;
  // FLOW: Latency Members
  boolean isLost;
  boolean p_isLost;
  long lastUpdate;
  int lastTime = 0;
  // FLOW: Angle Members
  boolean isRotating;
  int id;
  float deg;
  float preDeg;
  float targetAngle;
  // FLOW: Average Speed Members
  int aveFrameNum = 10;
  float ave_speedX;
  float ave_speedY;
  float pre_speedX[] = new float[aveFrameNum];
  float pre_speedY[] = new float[aveFrameNum];

  // FLOW: Probe Members
  boolean track;
  int direction;
  // FLOW: Detect Members
  boolean detect;
  int detectState;
  int detectObjectId;
  GridPosition detectObjectGridPosition;
  GridPosition detectStartingGridPosition;

  Cube(int i, boolean lost) {
    id = i;
    isLost = lost;
    p_isLost = lost;

    lastUpdate = System.currentTimeMillis();

    isRotating = false;

    for (int j = 0; j < aveFrameNum; j++) {
      pre_speedX[j] = 0;
      pre_speedY[j] = 0;
    }

    track = false;
    detect = false;
    detectState = DetectStates.get("None");
    detectObjectId = -1;
    detectObjectGridPosition = new GridPosition(-1, -1);
  }

  void resetCount() {
    count = 0;
  }

  boolean isAlive(long now) {
    return(now < lastUpdate + 200);
  }

  int[] aimslow(float tx, float ty) {
    int left = 0;
    int right = 0;
    float angleToTarget = atan2(ty-y, tx-x);
    float thisAngle = deg*PI/180;
    float diffAngle = thisAngle-angleToTarget;
    if (diffAngle > PI) diffAngle -= TWO_PI;
    if (diffAngle < -PI) diffAngle += TWO_PI;
    //if in front, go forward and
    if (abs(diffAngle) < HALF_PI) {
      //in front
      float frac = cos(diffAngle);
      //println(frac);
      if (diffAngle > 0) {
        //up-left
        left = floor(100*pow(frac, 1));
        right = 100;
      } else {
        left = 100;
        right = floor(100*pow(frac, 1));
      }
    } else {
      //face back
      if (diffAngle > 0) {
        left  = -30;
        right =  30;
      } else {
        left  =  30;
        right = -30;
      }
    }

    int[] res = new int[2];
    res[0]= left;
    res[1] = right;
    return res;
  }

  // FUNCTION: This function defines how the cubes aims at something the perceived behavior will strongly depend on this
  int[] aim(float tx, float ty) {
    int left = 0;
    int right = 0;
    float angleToTarget = atan2(ty-y, tx-x);
    float thisAngle = deg*PI/180;
    float diffAngle = thisAngle-angleToTarget;
    if (diffAngle > PI) diffAngle -= TWO_PI;
    if (diffAngle < -PI) diffAngle += TWO_PI;
    //if in front, go forward and
    if (abs(diffAngle) < HALF_PI) {
      //in front
      float frac = cos(diffAngle);
      if (diffAngle > 0) {
        //up-left
        left = floor(100*pow(frac, 2));
        right = 100;
      } else {
        left = 100;
        right = floor(100*pow(frac, 2));
      }
    } else {
      //face back
      float frac = -cos(diffAngle);
      if (diffAngle > 0) {
        left = -floor(100*frac);
        right = -100;
      } else {
        left = -100;
        right = -floor(100*frac);
      }
    }

    int[] res = new int[2];
    res[0] = left;
    res[1] = right;
    return res;
  }

  float distance(Cube o) {
    return distance(o.x, o.y);
  }

  float distance(float ox, float oy) {
    return sqrt((x - ox) * (x - ox) + (y - oy) * (y - oy));
  }
}
