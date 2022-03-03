(
// FFT
var n = 513;
var freqMin = 20;
var freqMax = 20000;
var fftStep = (freqMax-freqMin)/n;
n.do{
	arg i;
	var bottom = (i*fftStep) + freqMin;
	var top = bottom + fftStep;
	"FFT bin: %\t% Hz to % Hz".format(i,bottom,top).postln;
}
)

(
// MelBands
var n = 40;
var freqMin = 20;
var freqMax = 20000;
var lowMel =  1127.010498 * ((freqMin/700) + 1).log; // convert from hz to mels
var highMel = 1127.010498 * ((freqMax/700) + 1).log; // convert from hz to mels
var stepMel = (highMel - lowMel) / n;
var melpoints = n.collect{arg i; (i*stepMel) + lowMel} ++ highMel;
var freqpoints = ((melpoints / 1127.01048).exp - 1) * 700; // convert from mel to hz
var win = Window("MelBands",Rect(0,0,1600,400),false);
var uv;
win.background_(Color.white);
uv = UserView(win,Rect(0,0,win.bounds.width,win.bounds.height))
.drawFunc_{
	freqpoints.do{
		arg hz;
		var x = hz.linlin(20,20000,0,uv.bounds.width);
		Pen.color_(Color.red);
		// "Mel bin: %\t% Hz to % Hz".format(i,bottom,top).postln;
		Pen.line(Point(x,0),Point(x,uv.bounds.height));
		Pen.stroke;
	};
};

win.front;
win.refresh;
)