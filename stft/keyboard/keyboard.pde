PImage keyboard;
PFont f;

int sampleRate = 44100;
int windowSizes[] = {128, 256, 512, 1024, 2048, 4096};


void setup() {
  size(1025, 310, P2D);
  f = createFont("Arial", 14, true);
  keyboard = loadImage("Piano_88_keyboard_template_white.png");
}

void draw() {

  if (frameCount > (windowSizes.length-1)) noLoop();

  int windowSize = windowSizes[frameCount-1];

  textFont(f, 14);

  background(255);

  float keyboardWidth = 1000;
  float ratio = keyboardWidth / keyboard.width;
  float keyboardHeight = keyboard.height * ratio;
  image(keyboard, 0, 0, keyboardWidth, keyboardHeight);

  float startx = 10;
  float curr = startx;
  float inc = 11.2;
  float midiStart = 21;
  float midi = midiStart;
  int a = 0;

  float freqRes = float(sampleRate) / windowSize;

  while (curr < width) {
    fill(0);
    stroke(0);
    line(curr, keyboardHeight + 10, curr, keyboardHeight + 80);
    textAlign(LEFT);
    text(" A"+a, curr+2, keyboardHeight + 40);
    text(" MIDI: "+ int(midi), curr+2, keyboardHeight + 60);
    text(" " + round(midiToFreq(midi)) + " Hz", curr+2, keyboardHeight + 80);
    midi += 12;
    curr += (inc*12);
    a += 1;
  }

  float x = startx;
  //line(x, keyboardHeight + 90, x, keyboardHeight + 120);
  float currFreq = 0;
  int counter = 0;
  float prevx = 0;
  boolean toosmallsaid = true;

  while (true) {
    currFreq += freqRes;
    float m = freqToMidi(currFreq);
    x = ((m-midiStart) * inc) + startx;

    if (x > keyboardWidth) break;

    noStroke();
    if (x-prevx > 1.0) {
      if (counter % 2 == 0) {
        fill(200);
      } else {
        fill(150);
      };
      rect(prevx, keyboardHeight + 105, x-prevx, 20);

      fill(0);
      textAlign(LEFT);
      if (x-prevx > 20) text(counter, max(prevx+2, 2), keyboardHeight + 120);
    } else {
      if (toosmallsaid && x > 0) {
        fill(0);
        textAlign(LEFT);
        text("-->", x, keyboardHeight + 120);
        textAlign(RIGHT);
        text("too small to display the rest", x, keyboardHeight + 140);
        toosmallsaid = false;
        //println("toosmall", x,prevx);
      }
    }

    prevx = x;
    counter++;
  }

  if(toosmallsaid){
    text("-->", keyboardWidth, keyboardHeight + 120);
  }
  fill(0);
  textAlign(LEFT);
  text("Ordered FFT Bins (zero counting, so bin zero begins at 0 Hz)", startx + 2, keyboardHeight + 100);

  text("Sample Rate:          " + sampleRate + " Hz", startx, keyboardHeight + 140);
  text("Window Size:          " + windowSize + " samples", startx, keyboardHeight + 160);
  text("Frequency Resolution: " + freqRes + " Hz", startx, keyboardHeight + 180);

  saveFrame(frameCount + "_windowSize=" + windowSize + ".png");
}

float midiToFreq(float midi) {
  return pow(2, (midi-69)/12) * 440;
}

float freqToMidi(float freq) {
  return 69 + (12 * log2(freq/440));
}

float log2(float val) {
  return log(val) / log(2);
}
