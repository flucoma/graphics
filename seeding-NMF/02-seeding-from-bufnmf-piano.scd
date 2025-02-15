// start with an audio recording of the notes that we know will be present
~saw_scale = Buffer.read(s,thisProcess.nowExecutingPath.dirname+/+"00_saw_scale.wav");

// decompose scale to get the bases of the different notes
(
fork{
	~bases = Buffer(s);
	~activations = Buffer(s);
	~resynth = Buffer(s);
	FluidBufNMF.processBlocking(s,~saw_scale,bases:~bases,activations:~activations,components:8,resynth:~resynth,resynthMode:1);
	s.sync;
	defer{
		w = Window();
		w.layout = VLayout(
			FluidWaveform(~resynth,featuresBuffer:~activations,stackFeatures:true,normalizeFeaturesIndependently:false),
			FluidWaveform(featuresBuffer:~bases,stackFeatures:true)
		);
		w.front;
	};

	1.wait;

	~resynth.numChannels.do{
		arg i;
		{
			var sig = PlayBuf.ar(~resynth.numChannels,~resynth,BufRateScale.ir(~resynth),doneAction:2);
			sig[i].dup;
		}.play;

		~resynth.duration.wait;
	};
}
)

// seed with the bases of the different notes to *find* these notes in the melody
(
fork{
	~piano = Buffer.read(s,thisProcess.nowExecutingPath.dirname+/+"somewhere-over-the-rainbow.wav");
	FluidBufNMF.processBlocking(s,~piano,resynth:~resynth,resynthMode:1,bases:~bases,activations:~activations,basesMode:1,components:~bases.numChannels);
	s.sync;
	defer{ FluidWaveform(~resynth,featuresBuffer:~activations,stackFeatures:true,normalizeFeaturesIndependently:false) };

	2.wait;

	~resynth.numChannels.do{
		arg i;
		{
			var sig = PlayBuf.ar(~resynth.numChannels,~resynth,BufRateScale.ir(~resynth),doneAction:2);
			sig[i].dup;
		}.play;

		~resynth.duration.wait;
		1.wait;
	};
}
)