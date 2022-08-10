(
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+Date.localtime.stamp;
fork({
	var fw, img;
	b = Buffer.alloc(s,4410 * 0.5);
	~indices = Buffer(s);
	~src = Buffer.read(s,FluidFilesPath("Tremblay-AaS-SynthTwoVoices-M.wav"),0,44100 * 2);

	s.sync;

	{
		var sig = SinOsc.ar(110,0,0.3);
		sig = sig + Dust.ar(50);
		sig = sig.clip(-1,1);
		RecordBuf.ar(sig,b,loop:0,doneAction:2);
	}.play;

	b.duration.wait;
	0.1.wait;

	FluidBufTransientSlice.processBlocking(s,b,indices:~indices,minSliceLength:10);

	fw = FluidWaveform(b,~indices,bounds:Rect(0,0,1600,400),lineWidth:2);
	1.wait;
	img = Image.fromWindow(fw.parent);
	folder.mkdir;
	img.write(folder+/+"transients-sine.jpg");
	1.wait;
	fw.parent.close;

	FluidBufTransientSlice.processBlocking(s,~src,indices:~indices);

	s.sync;

	fw = FluidWaveform(~src,~indices,bounds:Rect(0,0,1600,400));
	1.wait;
	img = Image.fromWindow(fw.parent);
	folder.mkdir;
	img.write(folder+/+"transients-audio.jpg");
	1.wait;
	fw.parent.close;

},AppClock);
)