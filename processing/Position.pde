class Position {
  int x;
  int y;

  Position(int xPos, int yPos) {
    x = xPos;
    y = yPos;
  }
}

class GridPosition extends Position {
  boolean traveled;

  GridPosition(int xPos, int yPos) {
    super(xPos, yPos);
    traveled = false;
  }

  int xCoordinate(GridPosition pos) {
    return (MAT_STARTING_POS + (CUBE_SIZE / 2)) + ((pos.x * SQUARE_WIDTH) + (SQUARE_WIDTH / 2));
  }

  int yCoordinate(GridPosition pos) {
    return (MAT_STARTING_POS + (CUBE_SIZE / 2)) +  ((pos.y * SQUARE_HEIGHT) + (SQUARE_HEIGHT / 2));
  }
}
