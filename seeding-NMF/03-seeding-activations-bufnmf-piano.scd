(
fork{
	~hopSize = 512;
	~activations = Buffer.alloc(s,(~piano.numFrames / ~hopSize) + 1,8);
	s.sync;
	~buffer_of_ones = Buffer.loadCollection(s,Array.fill((~activations.numFrames / 8).floor,{1}));
	s.sync;
	8.do{
		arg i;
		FluidBufCompose.processBlocking(s,~buffer_of_ones,destination:~activations,destStartFrame:i * ~buffer_of_ones.numFrames,destStartChan:i);
	};
	s.sync;
	defer{ FluidWaveform(featuresBuffer:~activations,stackFeatures:true) }
}
)

(
fork{
	FluidBufNMF.processBlocking(s,~saw_scale,bases:~bases,activations:~activations,components:8,actMode:1,resynth:~resynth,resynthMode:1);
	s.sync;
	defer{
		w = Window();
		w.layout = VLayout(
			FluidWaveform(~resynth,featuresBuffer:~activations,stackFeatures:true),
			FluidWaveform(featuresBuffer:~bases,stackFeatures:true)
		);
		w.front;
	}
}
)

(
fork{
	FluidBufNMF.processBlocking(s,~piano,resynth:~resynth,resynthMode:1,bases:~bases,basesMode:2,activations:~activations,components:~bases.numChannels);
	s.sync;
	defer{ FluidWaveform(~resynth,featuresBuffer:~activations,stackFeatures:true,normalizeFeaturesIndependently:false) }
}
)