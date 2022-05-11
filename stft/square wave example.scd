(
s.waitForBoot{
	var tableSize = 256;
	var sq = Buffer.alloc(s,tableSize);
	var resynth = Buffer.alloc(s,tableSize);
	var mags, phases;
	var sound_example = Buffer(s);
	var compare_buf = Buffer(s);

	mags = Buffer.alloc(s,(tableSize/2)+1);
	phases = Buffer.alloc(s,(tableSize/2)+1);

	s.sync;

	sq.sine1(Array.fill((s.sampleRate * 0.5 * (1/tableSize)).floor.asInteger,{arg i; if((i%2)==0){1 / (i+1)}{0};}),true,false,true);
	s.sync;

	FluidBufSTFT.processBlocking(s,sq,magnitude:mags,phase:phases,windowSize:tableSize,padding:0,action:{"stft complete".postln});

	s.sync;

	// FluidWaveform(sq,imageBuffer:mags);

	mags.loadToFloatArray(action:{
		arg mags_fa;
		phases.loadToFloatArray(action:{
			arg phases_fa;

			FluidBufSTFT.processBlocking(s,magnitude:mags,phase:phases,resynth:sq,inverse:1,windowSize:tableSize,padding:0);

			FluidBufCompose.processBlocking(s,sq,destination:compare_buf);

			phases_fa = phases_fa.collect{
				arg ph;
				if(1.coin){ph = rrand(-pi,pi)};
				ph;
			};

			phases.loadCollection(phases_fa,action:{
				FluidBufSTFT.processBlocking(s,magnitude:mags,phase:phases,resynth:resynth,inverse:1,action:{
					fork{
						var disprange = 4;
						var curr = 0;
						"inverse stft done".postln;

						resynth.clip;
						s.sync;

						200.do{
							FluidBufCompose.processBlocking(s,sq,destination:sound_example,destStartFrame:curr);
							curr = curr + tableSize;
						};

						curr = curr + s.sampleRate;

						200.do{
							FluidBufCompose.processBlocking(s,resynth,destination:sound_example,destStartFrame:curr);
							curr = curr + tableSize;
						};

						FluidBufCompose.processBlocking(s,resynth,destination:compare_buf,destStartChan:1);

						s.sync;

						{
							FluidWaveform(featuresBuffer:compare_buf,stackFeatures:true,bounds:Rect(0,0,1600,400),lineWidth:2)
						}.defer;
					}
				},windowSize:tableSize,padding:0);

			});

		});

	});
}
)