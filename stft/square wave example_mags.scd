(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
s.waitForBoot{
	var tableSize = 256;
	var sq = Buffer.alloc(s,tableSize);
	var resynth = Buffer.alloc(s,tableSize);
	var mags = Buffer(s);
	var phases = Buffer(s);
	var sound_example = Buffer(s);
	var compare_buf = Buffer(s);
	var new_phases_buf = Buffer.alloc(s,1,(tableSize/2)+1);

	s.sync;

	sq.sine1(Array.fill((s.sampleRate * 0.5 * (1/tableSize)).floor.asInteger,{arg i; if((i%2)==0){1 / (i+1)}{0};}),true,false,true);
	s.sync;

	FluidBufSTFT.processBlocking(s,sq,magnitude:mags,phase:phases,windowSize:tableSize,padding:0,action:{"stft complete".postln});

	s.sync;

	mags.loadToFloatArray(action:{
		arg mags_fa;
		phases.loadToFloatArray(action:{
			arg phases_fa;

			fork({
				var new_mags = Buffer(s);
				mags.postln;
				phases.postln;
				FluidBufSTFT.processBlocking(s,magnitude:mags,phase:phases,resynth:sq,inverse:1,windowSize:tableSize,padding:0);
				FluidBufCompose.processBlocking(s,sq,destination:compare_buf);

				s.sync;

				outfolder.mkdir;
				[0.0,0.01,0.1,1.0].do{
					arg amtrand, i;
					var curr = 0, img, fw;
					var new_phases = phases_fa.collect{
						arg ph;
						if(amtrand.coin){ph = rrand(-pi,pi)};
						ph;
					};

					new_phases.size.postln;

					new_phases_buf.loadCollection(new_phases);

					s.sync;

					new_phases_buf.postln;
					mags.postln;

					FluidBufSTFT.processBlocking(s,magnitude:mags,phase:new_phases_buf,resynth:resynth,inverse:1,windowSize:tableSize,padding:0);

					s.sync;

					"inverse stft done".postln;
					FluidBufSTFT.processBlocking(s,resynth,magnitude:new_mags);


					resynth.clip;
					resynth.postln;
					s.sync;

					400.do{
						FluidBufCompose.processBlocking(s,sq,destination:sound_example,destStartFrame:curr);
						curr = curr + tableSize;
					};

					curr = curr + s.sampleRate;

					400.do{
						FluidBufCompose.processBlocking(s,resynth,destination:sound_example,destStartFrame:curr);
						curr = curr + tableSize;
					};

					FluidBufCompose.processBlocking(s,resynth,destination:compare_buf,destStartChan:1);

					s.sync;

					// waveforms
					fw = FluidWaveform(featuresBuffer:compare_buf,stackFeatures:true,bounds:Rect(0,0,1600,400),lineWidth:2);
					1.wait;
					img = Image.fromWindow(fw.parent);
					img.write(outfolder+/+"%_%pct_rand.png".format(i,amtrand),"png",100);
					1.wait;
					fw.close;

					// mags
					FluidBufSTFT.processBlocking(s,resynth,magnitude:new_mags);
					s.sync;
					fw = FluidWaveform(imageBuffer:new_mags,bounds:Rect(0,0,1600,400),imageColorScheme:1,imageColorScaling:1);
					1.wait;
					img = Image.fromWindow(fw.parent);
					img.write(outfolder+/+"%_%pct_rand_mags.png".format(i,amtrand),"png",100);
					1.wait;
					fw.close;

					s.sync;

					sound_example.write(outfolder+/+"%_%pct_rand.wav".format(i,amtrand),"wav");

					s.sync;
				}
			},AppClock);
		});
	});
}
)