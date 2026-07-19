import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import processing.sound.*;

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
}

void updateVolumes(){
  for(String path : sounds){
    float volume = 0.0;
    
    for(Shape s : circleFlower.shape_list){
      if(s.sound.equals(path) && s.state){
        volume += 0.4;
      }
    }
    
    volume *= master_volume;
    
    SoundFile sf = sound_files.get(path);
    if(sf != null){
      sf.amp(volume);
    }
  }
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
abstract class Shape {
  public Point p;
  public Point init_p;
  public float r;
  public boolean state;
  public int id;
  public String sound;
  public int depthLevel;
  public int branchIndex;
  
  public Shape(Point p,float r, int id, String sound){
    this.p = p;
    this.init_p = new Point(p.x, p.y);
    this.r = r;
    this.state = false;
    this.id = id;
    this.sound = sound;
  }

  public void render(float current_vol){
    if(state){
      blendMode(ADD);
      float blue = map(current_vol, 0, 0.5,150,90);
      float alpha = map(current_vol, 0, 0.5, 100, 90);
      fill(255,64,blue,alpha);
      noStroke();
      draw();
      blendMode(BLEND);
    }

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

class Hexagon extends Shape {
  public Hexagon(Point p, float r, int id, String sound){
    super(p,r,id,sound);
  }

  @Override
  protected void draw(){
    beginShape();
    for(int i=0;i<6;i++){
      float angle = radians(i*60);
      vertex(
        p.x + cos(angle)*r,
        p.y + sin(angle)*r
      );
    }
    endShape(CLOSE);
  }

  @Override
  public boolean contains(float mx, float my){
    return dist(mouseX, mouseY, p.x, p.y) < r;
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

  public abstract void update();
  public abstract void draw();
}

class CircleFlower extends Flower{
  public ArrayList<Shape> shape_list = new ArrayList<Shape>();

  public CircleFlower(Point center, float r, int max_depth){
    super(center,r,max_depth);

    int id = 0;
    for(FlowerPoint fp : points){
      String this_sound = sounds[id % sounds.length];
      Shape newShape = new Circle(fp.p,r,id,this_sound);
      shape_list.add(newShape);
      id++;
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
  }
}
CircleFlower circleFlower;

class LineFlower extends Flower {
  private float base_angle;
  public LineFlower(Point center, float r, int max_depth){
    super(center,r,max_depth);
    base_angle = 0;
  }
  

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
      if (n < 2) continue;
      stroke(255, 255, 10, 60);
      
      for (int i = 0; i < n; i++) {
        Point p1 = layerPoints.get(i).p;
        for (int j = i + 1; j < n; j++) {
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
LineFlower lineFlower;

// processing;
void setup(){
  fullScreen();
  smooth(8);
  background(0);
  
  audioSetup();
  
  Point center = new Point(width/2.0,height/2.0);
  Point linecenter = new Point(width/3.0,height/3.0);
  float r = 60.0;
  int depth = 2;

  circleFlower = new CircleFlower(center,r*1.5,depth); // rで大きさを変換
  lineFlower = new LineFlower(linecenter,r,depth);
}

void draw(){
  background(0);
  circleFlower.draw();
  lineFlower.draw();
  circleFlower.update();
  lineFlower.update();
}

void mousePressed(){
  if(mouseButton == RIGHT){
    for(Shape s : circleFlower.shape_list) s.state = false;
  } else {
    for (Shape s : circleFlower.shape_list) {
      if (s.contains(mouseX,mouseY)) {
        s.state = !s.state;
        println("Clicked ID: " + s.id + " | Sound: " + s.sound + " | State: " + s.state);
        break;
      }
    }
  }
  updateVolumes();
}

void mouseWheel(MouseEvent event){
  float e = event.getCount();
  if(e<0) master_volume += 0.1;
  else if(e>0) master_volume -= 0.1;
  
  master_volume = constrain(master_volume, 0.0, 2.0);
  updateVolumes();
}
