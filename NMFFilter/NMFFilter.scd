(
var stamp = Date.localtime.stamp;
var folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"output/%".format(stamp);

Window.closeAll;

~save_img = {
	arg win, path;
	var img = Image.fromWindow(win);
	img.write(path,"png",quality:100);
};
// get activations plots
s.waitForBoot{
	fork({
		var drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
		var song = Buffer.readChannel(s,FluidFilesPath("Tremblay-beatRemember.wav"),channels:[0]);
		var activations = Buffer(s);
		var dur_writeBuf;
		var resynth = Buffer(s);
		var n_components = 3;
		var example_dur_buf = Buffer(s);
		var mono_drums_dur;
		var filterbuf, actsbuf;
		var exampleDur = 5;
		var fw;
		var bases = Buffer.loadCollection(s,513.collect{
			arg i;
			var kick = 0;
			var snare = 0;
			var hh = i.linlin(0,512,1.0,pi).sin;

			if(i < 10,{kick = 1});

			if((i > 10) && (i < 100),{snare = 1});

			[kick,snare,hh];
		}.flatten,3);

		folder.mkdir;

		/*s.sync;
		fw = FluidWaveform(drums,bounds:Rect(0,0,1200,300),waveformColor:Color.black);
		s.sync;
		1.wait;
		~save_img.(fw.win,folder+/+"00_original_waveform.png");
		fw.close;
		s.sync;
		"original waveform saved".postln;

		~rasterBuf = Buffer(s);
		FluidBufMelBands.processBlocking(s,drums,features:~rasterBuf,windowSize:4096,hopSize:512,numBands:480);
		s.sync;
		fw = FluidWaveform(imageBuffer:~rasterBuf,imageColorScheme:0);
		s.sync;
		1.wait;
		~save_img.(fw.win,folder+/+"00_original_spectrogram_mel.png");
		fw.close;
		s.sync;
		"original spectrogram saved".postln;*/

		~fw = FluidWaveform(drums,waveformColor:Color.black,bounds:Rect(0,0,1600,400));
		s.sync;
		1.wait;
		~save_img.(~fw.win,folder+/+"00_orig.png");
		~fw.close;
		1.wait;

		"orig image created".postln;


		// process it:
		FluidBufNMF.processBlocking(s,drums,activations:activations,bases:bases,basesMode:1,resynth:resynth,components:n_components,action:{

			fork({

				[[bases,"Bases"],[activations,"Activations"]].do{
					arg arr;
					var buffer = arr[0];
					var name = arr[1];
					var fw;

					fw = FluidWaveform(featuresBuffer:buffer,bounds:Rect(0,0,1600,400),stackFeatures:true,normalizeFeaturesIndependently:false);
					s.sync;
					1.wait;
					~save_img.(fw.win,folder+/+"01_%_plot.png".format(name));
					fw.close;
					1.wait;

					"% plot created".format(name).postln;
				};

				// ==================== original sound ====================

				dur_writeBuf = Buffer.alloc(s,drums.numFrames,n_components);

				s.sync;

				{
					var dr = PlayBuf.ar(1,drums,BufRateScale.kr(drums),doneAction:2);
					var sig = FluidNMFFilter.ar(dr,bases,n_components);
					sig.poll;
					RecordBuf.ar(sig,dur_writeBuf);
				}.play;


				drums.duration.wait;
				1.wait;

				/*				dur_writeBuf.postln;
				dur_writeBuf.plot;*/

				~fw = FluidWaveform(dur_writeBuf,waveformColor:Color.black,bounds:Rect(0,0,1600,400));
				s.sync;
				1.wait;
				~save_img.(~fw.win,folder+/+"02_orig_through_nmffilter.png");
				~fw.close;
				1.wait;

				"orig_through_nmffilter image of all three created".postln;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,dur_writeBuf,startChan:i,numChans:1,destination:example_dur_buf);
					example_dur_buf.write(folder+/+"02_orig_through_nmffilter_%.wav".format(i+1),"wav");
				};

				s.sync;

				"original through nmffilter done".postln;

				// ==================== other sound ====================

				dur_writeBuf = Buffer.alloc(s,drums.numFrames,n_components);

				s.sync;

				{
					var dr = PlayBuf.ar(1,song,BufRateScale.kr(song),doneAction:2);
					var sig = FluidNMFFilter.ar(dr,bases,n_components);
					sig.poll;
					RecordBuf.ar(sig,dur_writeBuf);
				}.play;


				song.duration.wait;
				1.wait;

				/*				dur_writeBuf.postln;
				dur_writeBuf.plot;*/

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,dur_writeBuf,startChan:i,numChans:1,destination:example_dur_buf);
					example_dur_buf.write(folder+/+"03_song_through_nmffilter_%.wav".format(i+1),"wav");
				};

				s.sync;

				"song through nmffilter done".postln;

				// ================== filtering ==========================

				filterbuf = Buffer.alloc(s,s.sampleRate * exampleDur,n_components);

				{
					RecordBuf.ar(FluidNMFFilter.ar(PinkNoise.ar(0.dbamp),bases,n_components),filterbuf,loop:0,doneAction:2);
					Silence.ar;
				}.play;

				exampleDur.wait;
				1.wait;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,filterbuf,startChan:i,numChans:1,destination:example_dur_buf);
					example_dur_buf.write(folder+/+"04_base_%_filtering.wav".format(i+1),"wav");
				};

				s.sync;

				"filtered sound examples made".postln;

				// ============== enveloping =============================

				actsbuf = Buffer.alloc(s,drums.numFrames,n_components);
				mono_drums_dur = Buffer.alloc(s,drums.numFrames);

				s.sync;

				{
					var env = PlayBuf.ar(n_components,activations,BufRateScale.ir(activations),loop:0,doneAction:2);
					var sig = PinkNoise.ar(0.dbamp) * env;
					RecordBuf.ar(sig,actsbuf,loop:0,doneAction:2);
					// sig;
					Silence.ar;
				}.play;

				activations.duration.wait;
				1.wait;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,actsbuf,startChan:i,numChans:1,destination:mono_drums_dur);
					mono_drums_dur.write(folder+/+"05_activation_%_enveloping.wav".format(i+1),"wav");
				};

				s.sync;

				"enveloping noise examples made".postln;

				// ============== enveloping & filtering =============================

				s.sync;
				{
					var env = PlayBuf.ar(n_components,activations,BufRateScale.ir(activations),loop:0,doneAction:2);
					var sig = FluidNMFFilter.ar(PinkNoise.ar(0.dbamp),bases,n_components) * env;
					RecordBuf.ar(sig,actsbuf,loop:0,doneAction:2);
					// sig;
					Silence.ar;
				}.play;

				drums.duration.wait;
				1.wait;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,actsbuf,startChan:i,numChans:1,destination:mono_drums_dur);
					mono_drums_dur.write(folder+/+"06_enveloping_&_filtering_%.wav".format(i+1),"wav");
				};

				(n_components-1).do{
					arg i;
					FluidBufCompose.processBlocking(s,actsbuf,startChan:i,numChans:1,destination:mono_drums_dur,destGain:1);
				};

				mono_drums_dur.write(folder+/+"07_enveloping_&_filtering_mono.wav","wav");

				s.sync;

				"enveloping noise and filter examples made".postln;
				"done".postln;
			},AppClock);
		});
	},AppClock);
};
)