(
Window.closeAll;
s.waitForBoot{
	var ds = FluidDataSet(s);
	b = Buffer.readChannel(s,"/Volumes/Ted's 10TB My Book (June 2020)/SOUND DESIGNS/_INSTRUMENTAL SAMPLES/civic orchestra long tones/trumpet/trumpet D-001 D.wav",channels:[0]);
	s.sync;
	p = Buffer(s);
	q = Buffer(s);
	l = Buffer(s);
	FluidBufPitch.processBlocking(s,b,features:p,windowSize:4096,hopSize:4096);

	ds.fromBuffer(p);
	FluidNormalize(s).fitTransform(ds,ds);

	FluidBufLoudness.processBlocking(s,b,features:l);
	// FluidBufCompose.processBlocking(s,l,numChans:1,destination:p,destStartChan:2);

	s.sync;

	f = FluidWaveform(b,featuresBuffer:p,bounds:Rect(0,0,1600,400),stackFeatures:true);
	s.sync;
	1.wait;
	i = Image.fromWindow(f);
	s.sync;
	i.write("/Users/macprocomputer/dev/flucoma/graphics/outliers/outputs/%_trumpet_tone.png".format(Date.localtime.stamp),"png",100);
	// f.close;

	s.sync;

	ds.print;
	ds.dump({
		arg dict;
		defer{FluidPlotter(bounds:Rect(0,0,800,800),dict:dict)};
	});
}
)