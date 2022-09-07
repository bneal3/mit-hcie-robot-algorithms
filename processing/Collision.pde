class Collision {
  int id;
  int objectId;
  int x;
  int y;
  float deg;

  Collision(int i, int oi, int xPos, int yPos, float degAng) {
    id = i;
    objectId = oi;
    x = xPos;
    y = yPos;
    deg = degAng;
  }
}
