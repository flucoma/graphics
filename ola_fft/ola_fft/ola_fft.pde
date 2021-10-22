int window_size = 1024;
int hop_size = 512;
float display_height_scalar = 0.3;

Table wav_samples;
float[] downsampled;
float display_hop_size;
float display_window_size;
int display_scalar;

void setup(){
  size(1280,720);
  wav_samples = loadTable("Nicol-LoopE-M.wav_samples_210926_224117.csv");
  
  downsampled = new float[width];
  
  display_scalar = wav_samples.getRowCount() / width;
  println("display hop",display_scalar);
  
  for(int i = 0; i < downsampled.length; i++){
    int start = int(i * display_scalar);
    float max = 0;
    for(int j = 0; j < display_scalar; j++){
      float val = abs(wav_samples.getRow(start + j).getFloat(0));
      if(val > max) max = val;
    }
    downsampled[i] = max;
  }
}

void draw(){
  background(255);
  beginShape();
  stroke(0);
  int middle = height / 2;
  for(int i = 0; i < downsampled.length; i++){
    float yoff = map(downsampled[i],0,1,0,middle) * display_height_scalar;
    line(i,middle + yoff,i,middle - yoff);
  }
  
  stroke(255,0,0);
  float x = 0;
  while(x < width){
    line(x,0,x,height);
    //println(x);
    x += hop_size / float(display_scalar);
  }
}
