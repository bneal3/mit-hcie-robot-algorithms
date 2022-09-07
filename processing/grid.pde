GridPosition getGridPosition(int x, int y) {
  // FLOW: Run grid translation calculation
  int gridX = floor((x - (MAT_STARTING_POS + (CUBE_SIZE / 2))) / SQUARE_WIDTH);
  int gridY = floor((y - (MAT_STARTING_POS + (CUBE_SIZE / 2))) / SQUARE_HEIGHT);
  // FLOW: Check if off map
  if(gridX < 0) { gridX = 0; }
  if(gridY < 0) { gridY = 0; }
  if(gridX > grid.length - 1) { gridX = grid.length - 1; }
  if(gridY > grid[0].length - 1) { gridY = grid[0].length - 1; }
  // FLOW: Return grid position from grid array
  return grid[gridX][gridY];
}

void setGridTraveled(int x, int y) {
  GridPosition gridPosition = getGridPosition(x, y);
  if(!gridPosition.traveled) {
    gridPosition.traveled = true;
  }
}

// FLOW: Get angle to move towards destinations
float getAngleToTargetPosition(Cube cube, Position position) {
  float xDis = (cube.x - position.x) * 1.0;
  float yDis = (cube.y - position.y) * 1.0;
  float arctan = atan(yDis / xDis) * (180 / PI);
  float angle = 0;
  if(xDis < 0 && yDis >= 0) { // 4th quandrant
    angle = 270 + (arctan + 90);
  } else if(xDis >= 0 && yDis >= 0) { // 3rd quadrant
    angle = 270 - (90 - arctan);
  } else if(xDis >= 0 && yDis < 0) { // 2nd quandrant
    angle = 180 + arctan;
  } else { // 1st quadrant
    angle = arctan;
  }
  return angle;
}
