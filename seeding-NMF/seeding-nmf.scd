(
var stamp = Date.localtime.stamp;
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+"%_seeding-nmf".format(stamp);

~save_img = {
	arg win, path;
	var img = Image.fromWindow(win);
	img.write(path,"png",quality:100);
};
// get activations plots
s.waitForBoot{
	fork({
		var drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
		var activations = Buffer(s);
		var resynth = Buffer(s);
		var n_components = 3;
		var dur_writeBuf = Buffer(s);
		var example_dur_buf = Buffer(s);
		var fw;
		var linewidth = 2;
		var bases = Buffer.loadCollection(s,513.collect{
			arg i;
			var kick = 0;
			var snare = 0;
			var hh = i.linlin(0,512,0.0,pi).sin;

			if(i < 10,{kick = 1});

			if((i > 10) && (i < 100),{snare = 1});

			[kick,snare,hh];
		}.flatten,3);

		folder.mkdir;

		s.sync;

		fw = FluidWaveform(featuresBuffer:bases,bounds:Rect(0,0,1600,400),normalizeFeaturesIndependently:false,stackFeatures:true,lineWidth:linewidth);
		s.sync;
		1.wait;
		~save_img.(fw.win,folder+/+"00_seeded_bases.png");
		fw.close;
		"seeded bases image made".postln;

		s.sync;
		fw = FluidWaveform(drums,bounds:Rect(0,0,1600,400),waveformColor:Color.black,lineWidth:linewidth);
		s.sync;
		1.wait;
		~save_img.(fw.win,folder+/+"00_original_waveform.png");
		fw.close;
		s.sync;
		"original waveform saved".postln;

		~rasterBuf = Buffer(s);
		FluidBufMelBands.processBlocking(s,drums,features:~rasterBuf,windowSize:4096,hopSize:512,numBands:480);
		s.sync;
		fw = FluidWaveform(imageBuffer:~rasterBuf,imageColorScheme:1,imageColorScaling:1,lineWidth:linewidth);
		s.sync;
		1.wait;
		~save_img.(fw.win,folder+/+"00_original_spectrogram_mel.png");
		fw.close;
		s.sync;
		"original spectrogram saved".postln;

		// process it:
		FluidBufNMF.processBlocking(s,drums,activations:activations,bases:bases,basesMode:1,resynth:resynth,components:n_components,action:{

			fork({
				var filterbuf, exampleDur = 5, actsbuf;

				fw = FluidWaveform(resynth,bounds:Rect(0,0,1600,400),waveformColor:Color.black,lineWidth:linewidth);
				s.sync;
				1.wait;
				~save_img.(fw.win,folder+/+"00_resynth_buffer.png");
				fw.close;
				s.sync;

				"resynth buffer png created".postln;

				fw = FluidWaveform(
					resynth,
					featuresBuffer:activations,
					bounds:Rect(0,0,1600,400),
					stackFeatures:true,
					normalizeFeaturesIndependently:false,
					waveformColor:Color.black,
					lineWidth:linewidth
				);
				s.sync;
				1.wait;
				~save_img.(fw.win,folder+/+"00_resynth_buffer_with_activations.png");
				fw.close;
				s.sync;

				"activations png created".postln;

				[[bases,"Bases"],[activations,"Activations"]].do{
					arg arr;
					var buffer = arr[0];
					var name = arr[1];
					var fw;

					fw = FluidWaveform(featuresBuffer:buffer,bounds:Rect(0,0,1600,400),stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:linewidth);
					s.sync;
					1.wait;
					~save_img.(fw.win,folder+/+"01_%_plot.png".format(name));
					fw.close;
					1.wait;

					"% plot created".format(name).postln;
				};

				s.sync;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,resynth,startChan:i,numChans:1,destination:dur_writeBuf);
					s.sync;
					// dur_writeBuf.plot;
					dur_writeBuf.write(folder+/+"02_component_%.wav".format(i),"wav");
					s.sync;

					// ~rasterBuf = Buffer(s);
					FluidBufMelBands.processBlocking(s,resynth,startChan:i,numChans:1,features:~rasterBuf,windowSize:4096,hopSize:512,numBands:480);
					s.sync;
					fw = FluidWaveform(imageBuffer:~rasterBuf,imageColorScheme:1,imageColorScaling:1,lineWidth:linewidth);
					s.sync;
					1.wait;
					~save_img.(fw.win,folder+/+"05_resynth_spectrogram_mel_component_%.png".format(i));
					fw.close;
					s.sync;
					1.wait;
				};

				"components written to wav files".postln;

				s.sync;


				// ================== filtering ==========================

/*				filterbuf = Buffer.alloc(s,s.sampleRate * exampleDur,n_components);

				{
					RecordBuf.ar(FluidNMFFilter.ar(PinkNoise.ar(0.dbamp),bases,n_components),filterbuf,loop:0,doneAction:2);
					Silence.ar;
				}.play;

				exampleDur.wait;
				1.wait;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,filterbuf,startChan:i,numChans:1,destination:example_dur_buf);
					example_dur_buf.write(folder+/+"03_base_%_filtering.wav".format(i),"wav");
				};

				s.sync;

				"filtered sound examples made".postln;*/

				// ============== enveloping =============================

				/*actsbuf = Buffer.alloc(s,drums.numFrames,n_components);

				{
					var env = PlayBuf.ar(n_components,activations,BufRateScale.ir(activations),loop:0,doneAction:2);
					var sig = PinkNoise.ar(0.dbamp) * env;
					RecordBuf.ar(sig,actsbuf,loop:0,doneAction:2);
					// sig;
					Silence.ar;
				}.play;

				drums.duration.wait;
				1.wait;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,actsbuf,startChan:i,numChans:1,destination:dur_writeBuf);
					dur_writeBuf.write(folder+/+"04_activation_%_enveloping.wav".format(i),"wav");
				};

				"enveloping noise examples made".postln;*/
				"done".postln;
			},AppClock);
		});
	},AppClock);
};
)