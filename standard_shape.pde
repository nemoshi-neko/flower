class Circle extends Shape{
  public Circle(Point p, float r, int id, String sound){
    super(p,r,id,sound);
  }

  @Override
  protected void draw(){
    ellipse(p.x, p.y, r * 2, r * 2);
  }

  @Override
  public boolean contains(float mx, float my){
    return dist(mx, my, p.x, p.y) < r;
  }
}

class NGon extends Shape {
  private int sides;

  public NGon(Point p, float r, int id, String sound, int sides){
    super(p,r,id,sound);
    this.sides = sides;
  }

  @Override
  protected void draw(){
    beginShape();
    for(int i=0;i<sides;i++){
      float angle = radians(i*(360.0 / sides));
      vertex(
        p.x + cos(angle)*r,
        p.y + sin(angle)*r
      );
    }
    endShape(CLOSE);
  }

  @Override
  public boolean contains(float mx, float my){
    return dist(mx, my, p.x, p.y) < r * 0.9;
  }
}