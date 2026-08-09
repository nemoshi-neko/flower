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
  /*　同じ音を押したとき強くなる（ちょい重）
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