PFont f;

int sampleRate = 44100;
int windowSizes[] = {128, 256, 512, 1024, 2048, 4096};

void setup() {
  size(1400, 400, P2D);
  f = createFont("Arial", 14, true);
  //keyboard = loadImage("Piano_88_keyboard_template_white.png");
}

void draw() {

  if (frameCount > (windowSizes.length-1)) noLoop();

  int windowSize = windowSizes[frameCount-1];
  int n_numbers = 16;
  int display_n_bins = n_numbers * int(pow(2, frameCount-1));
  float freqRes = float(sampleRate) / windowSize;
  float maxfreq = freqRes * display_n_bins;

  int xmarginR = 40;
  int xmarginL = 80;
  int spectrogramWidth = width - (xmarginR + xmarginL);

  textFont(f, 14);

  background(255);
  int lineHeight = 40;
  int spectrogramHeight = lineHeight + 60;
  int spectrogramY = 200;

  fill(0);
  text("bin:", 4, spectrogramY + lineHeight + 20);

  float lineWidth = spectrogramWidth / n_numbers;
  textAlign(CENTER);
  for (int i = 0; i < n_numbers + 1; i++) {
    float x = (lineWidth * i) + xmarginR;

    line(x, spectrogramY, x, spectrogramY + lineHeight);
    int binnum = i * int(pow(2, frameCount-1));
    text(binnum, x, spectrogramY + lineHeight + 20);

    if (i < n_numbers) sublines(x, spectrogramY, lineWidth, lineHeight, frameCount-1);
  }

  fill(0);
  textAlign(LEFT);
  text("Ordered FFT Bins (zero counting, so bin zero begins at 0 Hz, each tick mark = 1 bin)", xmarginR, spectrogramHeight + spectrogramY);
  text("Sample Rate:          " + sampleRate + " Hz", xmarginR, spectrogramHeight + spectrogramY + 20);
  text("Window Size:          " + windowSize + " samples", xmarginR, spectrogramHeight + spectrogramY + 40);
  text("Frequency Resolution: " + freqRes + " Hz", xmarginR, spectrogramHeight + spectrogramY + 60);

  //for (int a = 0; a < 7; a++) {
  //  float hz = pow(2, a) * 27.5;
  //  float x = map(hz, 20, maxfreq, 0, spectrogramWidth) + xmargin;
  //  line(x, 0, x, spectrogramY - 10);
  //  text(a, x+4, 20);
  //}

  int prevBin = 0;
  for (int c = 0; c < 8; c++) {
    float hz = pow(2, c) * 32.703195662575;
    float x = map(hz, 0, maxfreq, 0, spectrogramWidth) + xmarginR;
    float y = c * 24;
    line(x, y, x, spectrogramY - 10);
    int binnum = int(hz / freqRes);
    int hz_i = int(round(hz));
    String txt = "C"+c+": "+hz_i+" hz, within bin: "+binnum;
    text(txt, x+4, y + 14);

    if (c > 0) {
      txt = "Number of bins from C"+(c-1)+" to C"+c+": "+(binnum-prevBin);
      y = (c * 20) - 8;
      text(txt, (xmarginR + spectrogramWidth) - 260, y + 14);
    }

    prevBin = binnum;
  }

  saveFrame("stretched_keyboard_" + frameCount + "_windowSize=" + windowSize + ".png");
}

void sublines(float x, float y, float lineWidth, float lineHeight, int depth) {
  if (depth > 0) {
    float newwidth = (lineWidth / 2);
    float newx = x + newwidth;
    float newheight = lineHeight * 0.75;

    line(newx, y, newx, y + newheight);

    sublines(x, y, newwidth, newheight, depth-1);
    sublines(newx, y, newwidth, newheight, depth-1);
  }
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
