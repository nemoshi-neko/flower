// Point
class Point {
    public float x;
    public float y;

    public Point(float x, float y) {
        this.x = x;
        this.y = y;
    }
}

class FlowerPoint {
  public Point init_p;
  public Point p;
  public int depth;
  public int idx;

  public FlowerPoint(Point p, int depth, int idx) {
    this.init_p = new Point(p.x, p.y);
    this.p = p;
    this.depth = depth;
    this.idx = idx;
  }
}