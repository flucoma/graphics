(
~out_folder = thisProcess.nowExecutingPath.dirname+/+"outputs/%_loudness_derivative".format(Date.localtime.stamp);
fork({
	~snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),202301,18354);
	~loudness = Buffer(s);
	~lus = Buffer(s);
	~stats = Buffer(s);

	s.sync;

	FluidBufLoudness.processBlocking(s,~snare,features:~loudness,windowSize:512);
	FluidBufSelect.processBlocking(s,~loudness,~lus,channels:[0]);
	FluidBufStats.processBlocking(s,~lus,stats:~stats,numDerivs:1);
	~lus.loadToFloatArray(action:{
		arg fa;
		fa.postln;
		fa.size.postln;
	});
	~stats.loadToFloatArray(action:{
		arg fa;
		fa.postln;
		"mean loudness:       %".format(fa[0]).postln;
		"1st derivative mean: %".format(fa[7]).postln;
	});

	s.sync;

	~fw = FluidWaveform(~snare,featuresBuffer:~lus,bounds:Rect(0,0,1600,400));
	s.sync;
	1.wait;
	~img = Image.fromWindow(~fw.win);
	~out_folder.mkdir;
	~img.write(~out_folder+/+"00_loudness_derivative.png","png",100);
	~fw.close;

	s.sync;

	~snare.reverse;

	FluidBufLoudness.processBlocking(s,~snare,features:~loudness,windowSize:512);
	FluidBufSelect.processBlocking(s,~loudness,~lus,channels:[0]);
	FluidBufStats.processBlocking(s,~lus,stats:~stats,numDerivs:1);
	~stats.loadToFloatArray(action:{
		arg fa;
		fa.postln;
		"mean loudness:       %".format(fa[0]).postln;
		"1st derivative mean: %".format(fa[7]).postln;
	});

	~fw = FluidWaveform(~snare,featuresBuffer:~lus,bounds:Rect(0,0,1600,400));
	s.sync;
	1.wait;
	~img = Image.fromWindow(~fw.win);
	~out_folder.mkdir;
	~img.write(~out_folder+/+"01_reversed_loudness_derivative.png","png",100);
	~fw.close;

},AppClock);
)