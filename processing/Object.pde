class Object {
  int id;
  int centerX;
  int centerY;
  ArrayList<Collision> collisions;

  Object(int i) {
    id = i;
    collisions = new ArrayList<Collision>();
  }
}
