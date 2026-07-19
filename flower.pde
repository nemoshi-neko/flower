import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import processing.sound.*;

// loading
boolean is_loaded = true;
String dot;
String dots;

// sound setting
TriOsc tri_osc;
Env env;

FFT fft;
int bands = 256;
float[] spectrum = new float[bands];

String[] sounds = {
  "../../sound/piano_melo1.mp3", //0
  
  // 2nd depth sound (6)
  "../../sound/strings1.mp3", "../../sound/choir1.mp3","../../sound/pad1.mp3",
  "../../sound/strings2.mp3", "../../sound/choir2.mp3","../../sound/pad2.mp3",

  // 3rd depth sound (18)
  "../../sound/bell.mp3", "../../sound/noise.mp3","../../sound/shakuhachi.mp3",
  "../../sound/bird1.mp3", "../../sound/pad_low.mp3", "../../sound/water.mp3",
  "../../sound/bird2.mp3", "../../sound/piano_melo2.mp3", "../../sound/windchime.mp3",
  "../../sound/campfire.mp3", "../../sound/shaker.mp3",// "../../sound/piano_chord.mp3",
  
  /*
  "../../sound/.mp3", "../../sound/.mp3",
  "../../sound/.mp3", "../../sound/.mp3", "../../sound/.mp3",
  "../../sound/.mp3", "../../sound/.mp3", "../../sound/.mp3",
  */
};

HashMap<String, SoundFile> sound_files = new HashMap<String, SoundFile>();
SoundFile base_sound;

HashMap<String, Amplitude> amp = new HashMap<String, Amplitude>();
float master_volume = 1.0;

void audioSetup(){
  fft = new FFT(this, bands);
  base_sound = new SoundFile(this, "../../sound/piano_melo1.mp3");
  
  for (int i = 0; i < sounds.length; i++) {
    String path = sounds[i];
    try {
      SoundFile sf = new SoundFile(this, sounds[i]);
      sf.amp(0.0); 
      sound_files.put(path, sf);
      Amplitude a = new Amplitude(this);
      a.input(sf);
      amp.put(path, a);
    } catch (Exception e) {
      println("error: cant load sound_file: " + sounds[i]);
    }
  }
  
  // ここで鳴らさないと音ズレがひどい
  base_sound.loop();
  for (String path : sounds) {
    SoundFile sf = sound_files.get(path);
    if (sf != null) sf.loop();
  }
  for (String path : sounds) {
    SoundFile sf = sound_files.get(path);
    if (sf != null) sf.amp(0);
  }
  is_loaded = true;
}

void updateVolumes(){
  for(SoundFile sf : sound_files.values()) sf.amp(0.0);

  for(Flower f : flowers){
    f.updateVolumes(sound_files, master_volume);
  }
  /*
  for(String path : sounds){
    float volume = 0.0;
    
    for(Shape s : shapeFlower.shape_list){
      if(s.sound.equals(path) && s.state){
        volume += 0.4;
      }
    }
    
    volume *= master_volume;
    
    SoundFile sf = sound_files.get(path);
    if(sf != null){
      sf.amp(volume);
    }
  }*/
}

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

// Shapes
interface ShapeFactory {
  Shape create(Point p, float r, int id, String sound);
}

abstract class Shape {
  public Point p;
  public Point init_p;
  public float r;
  public boolean state;
  public int id;
  public String sound;
  public int depthLevel;
  public int branchIndex;
  public int Color;
  
  public Shape(Point p,float r, int id, String sound){
    this.p = p;
    this.init_p = new Point(p.x, p.y);
    this.r = r;
    this.state = false;
    this.id = id;
    this.sound = sound;
    this.Color = color(255, 64, 150);
  }

  public void render(float current_vol){
    if(state){
      blendMode(ADD);
      float alpha = map(current_vol, 0, 0.5, 100, 90);
      fill(Color,alpha);
      noStroke();
      draw();
      blendMode(BLEND);
    }
  }

  public void postRender(){
    noFill();
    stroke(216);
    strokeWeight(1.5);
    draw();

    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(id, p.x, p.y);
  }

  protected abstract void draw();
  public abstract boolean contains(float mx, float my);
}

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
    return dist(mouseX, mouseY, p.x, p.y) < r;
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
      s.r = 90 * scale * r_scale;
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
      ArrayList<FlowerPoint> layerPoints = new ArrayList<FlowerPoint>();
      for (FlowerPoint fp : points) {
        if (fp.depth == d) {
          layerPoints.add(fp);
        }
      }
      
      int n = layerPoints.size();
      if (n < 3) continue;
      stroke(255, 255, 10, 60);
      
      for (int i = 0; i < n; i++) {
        Point p1 = layerPoints.get(i).p;
        for (int j = i + 1; j < n; j++) {
          int diff = j-i;
          if(min(diff,n-diff) < 3) continue;
          Point p2 = layerPoints.get(j).p;
          line(p1.x, p1.y, p2.x, p2.y);
        }
      }
    }
    blendMode(BLEND);
  }

  @Override
  public void update(){
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

// processing;
void setup(){
  fullScreen();
  smooth(8);
  dot = ".";
  
  Point left = new Point(width/4.0,height/2.0);
  Point center = new Point(width/2.0,height/2.0);
  Point right = new Point(width*3/4.0,height/2.0);
  float r = 60.0;
  int depth = 2;

  flowers.add(new ShapeFlower(center,r*1.5,depth,
    (p,radius,id,sound) -> new Circle(p,radius,id,sound)
  )); // rで大きさを変換
  flowers.add(new LineFlower(left,r*2,depth));
  flowers.add(new ShapeFlower(right,r,depth,
    (p,radius,id,sound) -> {
      NGon ngon = new NGon(p,radius,id,sound, 6);
      ngon.Color = color(10, 50, 155);
      return ngon;
    }
  ));
  
  // thread("audioSetup");
}

void nowLoading(){
  background(0);

  int dotCount = (frameCount / 30) % 3;
  for(dots = ".";dotCount>0;dotCount--) dots += dot;

  fill(255, 150 + sin(frameCount * 0.01) * 105);
  textAlign(LEFT,BOTTOM);
  textSize(24);
  text("now Loading" + dots, width-200, height-40);
}

void mainLoop(){
  background(0);
  for(Flower f : flowers){
    f.update();
    f.draw();
  }
}

void draw(){
  if(!is_loaded) nowLoading();
  else mainLoop();
}

void mousePressed(){
  for(Flower f : flowers) f.mousePressed(mouseX, mouseY, mouseButton);
  updateVolumes();
}

void mouseWheel(MouseEvent event){
  float e = event.getCount();
  if(e<0) master_volume += 0.1;
  else if(e>0) master_volume -= 0.1;
  
  master_volume = constrain(master_volume, 0.0, 2.0);
  updateVolumes();
}
