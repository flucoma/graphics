(
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+Date.localtime.stamp;
fork({
	var fw, img;
	b = Buffer.alloc(s,4410 * 0.5);
	~transients = Buffer(s);
	~residual = Buffer(s);
	~src = Buffer.read(s,FluidFilesPath("Tremblay-AaS-SynthTwoVoices-M.wav"),0,44100 * 2);

	s.sync;

	{
		var sig = SinOsc.ar(110,0,0.3);
		sig = sig + Dust.ar(100);
		sig = sig.clip(-1,1);
		RecordBuf.ar(sig,b,loop:0,doneAction:2);
	}.play;

	b.duration.wait;
	0.1.wait;

	FluidBufTransients.processBlocking(s,b,transients:~transients,residual:~residual);
	FluidBufCompose.processBlocking(s,~transients,destination:b,destStartChan:1);
	FluidBufCompose.processBlocking(s,~residual,destination:b,destStartChan:2);


	fw = FluidWaveform(bounds:Rect(0,0,1600,400),featuresBuffer:b,stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:2);
	1.wait;
	img = Image.fromWindow(fw.parent);
	folder.mkdir;
	img.write(folder+/+"transients-sine.jpg");
	1.wait;
	fw.parent.close;

	~transients = Buffer(s);
	~residual = Buffer(s);
	~compare = Buffer(s);
	FluidBufTransients.processBlocking(s,~src,transients:~transients,residual:~residual);
	FluidBufCompose.processBlocking(s,~src,destination:~compare,destStartChan:0);
	FluidBufCompose.processBlocking(s,~transients,destination:~compare,destStartChan:1);
	FluidBufCompose.processBlocking(s,~residual,destination:~compare,destStartChan:2);

	~src.write(folder+/+"src.wav");
	~transients.write(folder+/+"transients.wav");
	~residual.write(folder+/+"residual.wav");

	s.sync;

	fw = FluidWaveform(~compare,bounds:Rect(0,0,1600,1200));
	1.wait;
	img = Image.fromWindow(fw.parent);
	folder.mkdir;
	img.write(folder+/+"transients-audio.jpg");
	1.wait;
	fw.parent.close;

},AppClock);
)