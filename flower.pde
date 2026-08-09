import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import processing.sound.*;

// processing
void setup(){
  fullScreen();
  smooth(8);
  dot = ".";
  
  Point left = new Point(width/4.0,height/2.0);
  Point center = new Point(width/2.0,height/2.0);
  Point right = new Point(width*3/4.0,height/2.0);
  float r = 60.0;
  int depth = 2;

  /*
  flowers.add(new ShapeFlower(center,r*1.5,depth,
    (p,radius,id,sound) -> new Circle(p,radius,id,sound)
  )); // rで大きさを変換
  flowers.add(new LineFlower(left,r*2,depth));
  flowers.add(new ShapeFlower(right,r,depth,
    (p,radius,id,sound) -> {
      NGon ngon = new NGon(p,radius,id,sound, 6);
      ngon.shape_color = color(10, 50, 155);
      return ngon;
    }
  ));*/

  flowers.add(new ShapeFlower(center,r*2,depth,
    (p,radius,id,sound) -> new ShapeFlower(p,radius*0.2,2,
      (p2,radius2,id2,sound2) -> new Circle(p2,radius2,id2,sound2)
    )
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
