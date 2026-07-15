import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import processing.sound.*;

TriOsc tri_osc;
Env env;

// sound setting
String[] sounds = {
  "../../sound/piano1.wav", //0
  
  // 2nd depth sound (6)
  "../../sound/strings1.wav", "../../sound/choir.wav","../../sound/pad.wav",
  "../../sound/strings2.wav", "../../sound/choir2.wav","../../sound/pad2.wav",

  // 3rd depth sound (18)
  "../../sound/bell.wav", "../../sound/pad_low.wav","../../sound/shakuhachi.wav",
  "../../sound/bird.wav", "../../sound/piano_melo.wav", "../../sound/water.wav",
  "../../sound/birds.wav", "../../sound/piano_base.wav", "../../sound/windchime.wav",
  "../../sound/campfire.wav", "../../sound/shaker.wav",// "../../sound/piano_base.wav",
  
  /*
  "../../sound/.wav", "../../sound/.wav",
  "../../sound/.wav", "../../sound/.wav", "../../sound/.wav",
  "../../sound/.wav", "../../sound/.wav", "../../sound/.wav",
  */
};

HashMap<String, SoundFile> sound_files = new HashMap<String, SoundFile>();
SoundFile base_sound;

HashMap<String, Amplitude> amp = new HashMap<String, Amplitude>();
float master_volume = 1.0;

void audioSetup(){
  base_sound = new SoundFile(this, "../../sound/piano_base.wav");
  
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
    
    for(Circle c : circles.list){
      if(c.sound.equals(path) && c.state){
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

class Points{
  public ArrayList<Circle> list = new ArrayList<Circle>();
  private HashSet<String> visited = new HashSet<String>();
  private int id;

  public Points() {
    this.list = new ArrayList<Circle>();
    this.visited = new HashSet<String>();
    this.id = 0;
  }
  
  public void add(Point p, float r){
    String key = pointKey(p);
    if (!visited.contains(key)) {
      visited.add(key);
      String this_sound = sounds[id % sounds.length];
      Circle newCircle = new Circle(p,r,id,this_sound);
      this.list.add(newCircle);
      id++;
    }
  }
}

// Circle
class Circle {
  public Point p;
  public Point init_p;
  public float r;
  public boolean state;
  public int id;
  public String sound;
  public int depthLevel;
  public int branchIndex;
  
  public Circle(Point p,float r, int id, String sound){
    this.p = p;
    this.init_p = new Point(p.x, p.y);
    this.r = r;
    this.state = false;
    this.id = id;
    this.sound = sound;
  }
}

class Circles{
  public ArrayList<Circle> list = new ArrayList<Circle>();
  private HashSet<String> visited = new HashSet<String>();
  private int id;

  public Circles() {
    this.list = new ArrayList<Circle>();
    this.visited = new HashSet<String>();
    this.id = 0;
  }
  
  public void add(Point p, float r){
    String key = pointKey(p);
    if (!visited.contains(key)) {
      visited.add(key);
      String this_sound = sounds[id % sounds.length];
      Circle newCircle = new Circle(p,r,id,this_sound);
      this.list.add(newCircle);
      id++;
    }
  }
}
Circles circles;

// Flower
abstract class Flower {
  public Point center;
  protected int max_depth = 3;
  protected float r;
  public ArrayList<FlowerPoints> points = new ArrayList<FlowerPoint>();
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
          if(addPoint(next_p,r,idx)) idx++;
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
  public ArrayList<Circle> circleList = new ArrayList<Circle>();

  public CircleFlower(Point center, float r, int max_depth){
    super(center,r,max_depth);

    int id = 0;
    for(FlowerPoint fp : points){
      String this_sound = sounds[id % sounds.length];
      Circle newCircle = new Circle(p,r,id,this_sound);
      this.list.add(newCircle);
      id++;
    }
  }

  @Override
  public void update(){
    float angle = frameCount * 0.0005;
    float scale = 1.0 + sin(frameCount * 0.01) * 0.04;
    float r_scale = 1.5 + sin(frameCount * 0.002);
    for(Circle c : circles.list){
      Point d = new Point(
        c.init_p.x - center.x,
        c.init_p.y - center.y
      );

      d.x *= scale; d.y *= scale;

      Point r = new Point(
        d.x*cos(angle) - d.y*sin(angle),
        d.x*sin(angle) + d.y*cos(angle)
      );
      
      c.p.x = center.x + r.x;
      c.p.y = center.y + r.y;
      c.r = 90 * scale * r_scale;
    }
  }

  @Override
  public void draw(){
    blendMode(ADD);
    for (Circle c : circles.list) {
      float current_vol = 0; 
      Amplitude current_amp = amp.get(c.sound);
      if(current_amp != null)
        current_vol = current_amp.analyze()*8;
    
      if (c.state) {
        float blue = map(current_vol, 0, 0.5,150,90);
        float alpha = map(current_vol, 0, 0.5, 100, 90);
        fill(255,64,blue,alpha);
        ellipse(c.p.x, c.p.y, c.r * 2, c.r * 2);
      }
    }
    noFill();
    blendMode(BLEND);
    stroke(216);
    strokeWeight(1.5);
    for(Circle c : circles.list){
      ellipse(c.p.x, c.p.y, c.r * 2, c.r * 2);
    }
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
  
    for (Circle c : circles.list) {
      text(c.id, c.p.x, c.p.y);
    }
  }
}

class LineFlower extends Flower {
  public LineFlower(Point center, float r, int max_depth){
    super(center,r,max_depth);
  }
}

// processing
void setup(){
  fullScreen();
  smooth(8);
  background(0);
  
  audioSetup();
  circles = new Circles();
  
  Point center = new Point(width/2.0,height/2.0);
  float r = 60.0;

  circleFlower = new CircleFlower(center,r*1.5,depth); // rで大きさを変換
  println(circles.list.size());
}

void draw(){
  background(0);
  circleFlower.draw();
  circleFlower.update();
}

void mousePressed(){
  if(mouseButton == RIGHT){
    for(Circle c : circles.list) c.state = false;
  } else {
    for (Circle c : circles.list) {
      float d = dist(mouseX, mouseY, c.p.x, c.p.y);
    
      if (d < c.r) {
        c.state = !c.state;
        println("Clicked ID: " + c.id + " | Sound: " + c.sound + " | State: " + c.state);
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
