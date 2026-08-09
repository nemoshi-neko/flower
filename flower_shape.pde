// Flower
abstract class Flower {
  public Point center;
  protected int max_depth;
  protected float r;
  public ArrayList<FlowerPoint> points = new ArrayList<FlowerPoint>();
  private HashSet<String> visited = new HashSet<String>();

  public Flower(Point center, float r, int max_depth){
    this.center = center;
    this.r = r;
    this.max_depth = max_depth;
    plant();
  }

  String pointKey(Point p){
    return round(p.x) + "," + round(p.y);
  }

  private boolean addPoint(Point p, int d, int idx){
    String key = pointKey(p);
    if(!visited.contains(key)){
      visited.add(key);
      points.add(new FlowerPoint(p,d,idx));
      return true;
    }
    else return false;
  }

  private void plant(){
    Point[] d = new Point[6];
    for(int i=0;i<6;i++){
      float angle = radians(i*60);
      d[i] = new Point(cos(angle)*r,sin(angle)*r);
    }

    addPoint(center,0,0);

    for(int depth=1;depth<=max_depth;depth++){
      float cx = center.x+d[0].x*depth;
      float cy = center.y+d[0].y*depth;
      int idx = 0;
      for(int i=0;i<6;i++){
        int move_dir = (i+2)%6;
        for(int step=0;step<depth;step++){
          Point next_p = new Point(cx,cy);
          if(addPoint(next_p,depth,idx)) idx++;
          cx += d[move_dir].x;
          cy += d[move_dir].y;
        }
      }
    }
  }

  public abstract void mousePressed(float mx, float my, int button);
  public abstract void updateVolumes(HashMap<String,SoundFile> sound_files, float master_volume);

  public abstract void update();
  public abstract void draw();
}
ArrayList<Flower> flowers = new ArrayList<Flower>();

class ShapeFlower extends Flower{
  public ArrayList<Shape> shape_list = new ArrayList<Shape>();

  public ShapeFlower(Point center, float r, int max_depth, ShapeFactory factory){
    super(center,r,max_depth);

    int id = 0;
    for(FlowerPoint fp : points){
      String this_sound = sounds[id % sounds.length];
      Shape newShape = factory.create(fp.p,r,id,this_sound);
      shape_list.add(newShape);
      id++;
    }
  }

  @Override
  public void mousePressed(float mx, float my, int button){
    if(mouseButton == RIGHT){
      for(Shape s : shape_list) s.state = false;
    } else {
      for (Shape s : shape_list) {
        if (s.contains(mouseX,mouseY)) {
          s.state = !s.state;
          println("Clicked ID: " + s.id + " | Sound: " + s.sound + " | State: " + s.state);
          break;
        }
      }
    }
  }

  @Override
  public void updateVolumes(HashMap<String,SoundFile> sound_files, float master_volume){
    for(Shape s : shape_list){
      if(s.state){
        SoundFile sf = sound_files.get(s.sound);
        if(sf != null) sf.amp(0.4*master_volume);
      }
    }
  }

  @Override
  public void update(){
    float angle = frameCount * 0.0005;
    float scale = 1.0 + sin(frameCount * 0.01) * 0.04;
    float r_scale = 1.5 + sin(frameCount * 0.002);
    for(Shape s : shape_list){
      Point d = new Point(
        s.init_p.x - center.x,
        s.init_p.y - center.y
      );

      d.x *= scale; d.y *= scale;

      Point r = new Point(
        d.x*cos(angle) - d.y*sin(angle),
        d.x*sin(angle) + d.y*cos(angle)
      );
      
      s.p.x = center.x + r.x;
      s.p.y = center.y + r.y;
      s.r = s.init_r * scale * r_scale;
    }
  }

  @Override
  public void draw(){
    for (Shape s : shape_list){
      float current_vol = 0;
      Amplitude current_amp = amp.get(s.sound);
      if(current_amp != null)
        current_vol = current_amp.analyze()*8;
      
      s.render(current_vol);
    }
    for (Shape s : shape_list) s.postRender();
  }
}

class LineFlower extends Flower {
  private float base_angle;
  private float lerp_vol;

  public LineFlower(Point center, float r, int max_depth){
    super(center,r,max_depth);
    base_angle = 0;
  }
  
  @Override
  public void mousePressed(float mx, float my, int button){};
  @Override
  public void updateVolumes(HashMap<String, SoundFile> sound_files, float master_volume){};

  @Override
  public void draw(){
    blendMode(ADD);
    noFill();

    for (int d = 1; d <= max_depth; d++) {
      ArrayList<FlowerPoint> layer_points = new ArrayList<FlowerPoint>();
      for (FlowerPoint fp : points) {
        if (fp.depth == d) {
          layer_points.add(fp);
        }
      }
      
      int n = layer_points.size();
      if (n < 3) continue;

      float color_amt = map(lerp_vol,0,0.5, 0.0, 1.0);
      color_amt = constrain(color_amt, 0.0, 1.0);
      int max_color = color(64, 255, 255, 200);
      int line_color = lerpColor(color(255,255,64,200),max_color,color_amt);
      stroke(line_color);
      strokeWeight(1.5);
      
      for (int i = 0; i < n; i++) {
        Point p1 = layer_points.get(i).p;
        for (int j = i + 1; j < n; j++) {
          int diff = j-i;
          if(min(diff,n-diff) < 3) continue;
          Point p2 = layer_points.get(j).p;
          line(p1.x, p1.y, p2.x, p2.y);
        }
      }
    }
    blendMode(BLEND);
  }

  @Override
  public void update(){
    float volume = 0;
    for(String path : sounds){
      Amplitude a = amp.get(path);
      if(a!=null) volume += a.analyze()*8.0;
    }
    lerp_vol = lerp(lerp_vol,volume,0.1);

    float angle;
    float speed = 1.0 - 0.85 * cos(12*base_angle);
    base_angle += 0.01 * speed;
    
    for(FlowerPoint fp : points){
      Point d = new Point(
        fp.init_p.x - center.x,
        fp.init_p.y - center.y
      );

      if(fp.depth%2 == 1) angle = base_angle;
      else angle = -base_angle;

      fp.p.x = center.x + d.x*cos(angle) - d.y*sin(angle);
      fp.p.y = center.y + d.x*sin(angle) + d.y*cos(angle);
    }
  }
}