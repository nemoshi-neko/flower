// Shape
interface ShapeFactory {
  Shape create(Point p, float r, int id, String sound);
}

abstract class Shape {
  public Point p;
  public Point init_p;
  public float r;
  public float init_r;
  public boolean state;
  public int id;
  public String sound;
  public int depthLevel;
  public int branchIndex;
  public int shape_color;
  
  public Shape(Point p,float r, int id, String sound){
    this.p = p;
    this.init_p = new Point(p.x, p.y);
    this.r = r;
    this.init_r = r;
    this.state = false;
    this.id = id;
    this.sound = sound;
    this.shape_color = color(255, 64, 150);
  }

  public void render(float current_vol){
    if(state){
      blendMode(ADD);
      float alpha = map(current_vol, 0, 0.5, 100, 90);
      fill(shape_color,alpha);
      noStroke();
      draw();
      blendMode(BLEND);
    }
  }

  private void drawOutline(){
    noFill();
    stroke(216);
    strokeWeight(1.5);
    draw();
  }
  private void drawText(){
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(id, p.x, p.y);
  }
  public void postRender(){
    drawOutline();
    drawText();
  }

  protected abstract void draw();
  public abstract boolean contains(float mx, float my);
}