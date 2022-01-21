(
~folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"outputs"+/+Date.localtime.stamp;
s.waitForBoot{
	~drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));// first, let's make two new buffers called...
	~bases = Buffer.loadCollection(s,513.collect{
		arg i;
		var kick = 0;
		var snare = 0;
		var hh = i.linlin(0,512,1.0,pi).sin;

		if(i < 10,{kick = 1});

		if((i > 10) && (i < 100),{snare = 1});

		[kick,snare,hh];
	}.flatten,3);
	~activations = Buffer(s);
	~n_components = 3;

	~folder.mkdir;

	s.sync;

	FluidBufNMF.processBlocking(s,~drums,bases:~bases,basesMode:1,activations:~activations,components:~n_components,action:{"nmf done".postln;});

	~rec_buf = Buffer.alloc(s,~drums.numFrames / s.options.blockSize,~n_components);

	s.sync;

	{
		var sig = PlayBuf.ar(1,~drums,BufRateScale.kr(~drums),doneAction:2);
		var match = FluidNMFMatch.kr(sig,~bases,~n_components).poll;
		RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
	}.play;

	~drums.duration.wait;
	1.wait;

	"drums nmf match done".postln;

	~fw = FluidWaveform(~drums,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:true,waveformColor:Color(*0.9.dup(3)),normalizeFeaturesIndependently:false);

	1.wait;

	~img = Image.fromWindow(~fw.win);

	// ~img.plot;

	~img.write(~folder+/+"00_drums_nmf_match.png",quality:100);

	s.sync;

	~fw.close;

	"^ plot made".postln;

	//=========================================================================

	~song = Buffer.readChannel(s,FluidFilesPath("Tremblay-beatRemember.wav"),channels:[0]);

	s.sync;

	~rec_buf = Buffer.alloc(s,~song.numFrames / s.options.blockSize,~n_components);

	{
		var sig = PlayBuf.ar(1,~song,BufRateScale.kr(~song),doneAction:2);
		var match = FluidNMFMatch.kr(sig,~bases,~n_components).poll;
		RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
	}.play;

	~song.duration.wait;
	1.wait;

	"song nmf match done".postln;

	~fw = FluidWaveform(~song,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:true,waveformColor:Color(*0.9.dup(3)),normalizeFeaturesIndependently:false);
	1.wait;

	~img = Image.fromWindow(~fw.win);

	// ~img.plot;

	~img.write(~folder+/+"01_song_nmf_match.png",quality:100);

	"^ plot made".postln;

	~fw.close;
	//==============================================================================================================

	~rec_buf = Buffer.alloc(s,~song.numFrames,3);

	s.sync;

	{
		var sig = PlayBuf.ar(1,~song,BufRateScale.kr(~song),doneAction:2);
		var match = FluidNMFFilter.ar(sig,~bases,~n_components).poll;
		RecordBuf.ar(match,~rec_buf,loop:0,doneAction:2);
	}.play;

	~song.duration.wait;
	1.wait;

	"song nmf filter made".postln;

	~mono_buf = Buffer.alloc(s,~song.numFrames);

	~n_components.do{
		arg i;
		FluidBufCompose.processBlocking(s,~rec_buf,startChan:i,numChans:1,destination:~mono_buf);
		~mono_buf.write(~folder+/+"02_song_component_%.wav".format(i+1),"wav");
	};

	"^ audio files written".postln;

	s.sync;

	//=================================== dog ===================================

	// FluidNMFMatch can be trained on a small section of audio and then used to identify whenever similar audio
	// appears again in the whole file or other files

	// for example, take this 22 second field recording that has _some_ dog barking in it
	~golcar = Buffer.readChannel(s,FluidFilesPath("Tremblay-BaB-SoundscapeGolcarWithDog.wav"),channels:[0]);

	s.sync;

	~golcar4s = Buffer.readChannel(s,FluidFilesPath("Tremblay-BaB-SoundscapeGolcarWithDog.wav"),numFrames:~golcar.sampleRate * 4,channels:[0]);

	// ~golcar.play;
	s.sync;

	~golcar4s.write(~folder+/+"03_golcar4sec.wav","wav");

	// we'll do a FluidBufNMF analysis on just the first 4 seconds (the part that has some dog bark in it);
	~bases = Buffer(s);
	~activations = Buffer(s);
	~resynth = Buffer(s);
	FluidBufNMF.processBlocking(s,~golcar4s,bases:~bases,activations:~activations,resynth:~resynth,components:2,action:{"nmf done".postln;});

	~mono_buf = Buffer.alloc(s,~golcar4s.numFrames);

	s.sync;

	2.do{
		arg i;
		FluidBufCompose.processBlocking(s,~resynth,startChan:i,numChans:1,destination:~mono_buf);
		~mono_buf.write(~folder+/+"03_golcar4s_component_%.wav".format(i+1),"wav");
	};

	s.sync;

	"golcar4s audio buffers written".postln;

	~fw = FluidWaveform(featureBuffer:~bases,bounds:Rect(0,0,1200,300),stackFeatures:true,normalizeFeaturesIndependently:false);
	1.wait;

	~img = Image.fromWindow(~fw.win);

	// ~img.plot;

	~img.write(~folder+/+"04_golcar4sec_bases.png",quality:100);
	s.sync;
	~fw.close;

	~fw = FluidWaveform(~golcar4s,featureBuffer:~activations,bounds:Rect(0,0,1200,300),stackFeatures:true,normalizeFeaturesIndependently:false);
	1.wait;

	~img = Image.fromWindow(~fw.win);
	// ~img.plot;
	~img.write(~folder+/+"05_golcar4sec_activation.png",quality:100);
	s.sync;


	// and then play the whole 22 second sound file through FluidNMFMatch to see where in the sound file the spectral template
	// of the dog bark is found. because the FluidBufNMF analysis starts from a stochastic state, we can't be sure which base
	// contains the dog bark, but watching the green bars in this window will make very clear which one is detecting where
	// in the sound file a dog bark is found

	~rec_buf = Buffer.alloc(s,~golcar.numFrames / s.options.blockSize,2);

	s.sync;

	{
		var sig = PlayBuf.ar(1,~golcar,BufRateScale.ir(~golcar),doneAction:2); // play the whole sound file
		var match = FluidNMFMatch.kr(sig,~bases,2);
		match.poll(label:"golcar match");
		RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
		// 30 times per second send the output of FluidNMFMatch to the language
		SendReply.kr(Impulse.kr(30),"/nmfmatch",match);
		// sig;
	}.play;

	~golcar.duration.wait;
	1.wait;

	~fw = FluidWaveform(~golcar,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:true,normalizeFeaturesIndependently:false);
	1.wait;

	~img = Image.fromWindow(~fw.win);

	// ~img.plot;

	~img.write(~folder+/+"06_golcar_activations_stacked=true.png",quality:100);
	s.sync;
	~fw.close;

	// ============================== stack = false;
	~fw = FluidWaveform(~golcar,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:false,normalizeFeaturesIndependently:false);
	1.wait;

	~img = Image.fromWindow(~fw.win);

	// ~img.plot;

	~img.write(~folder+/+"06_golcar_activations_stacked=false.png",quality:100);
	s.sync;
	~fw.close;


	Window.closeAll;

	"--- all done".postln;
};
)