(
// get activations plots
s.waitForBoot{
	fork({
		var drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
		var bases = Buffer(s);
		var activations = Buffer(s);
		var resynth = Buffer(s);
		var n_components = 3;
		var dur_writeBuf = Buffer(s);
		var example_dur_buf = Buffer(s);
		var stamp = Date.localtime.stamp;
		var folder = "/Users/macprocomputer/Desktop/_flucoma/code/graphics/BufNMF/output/%".format(stamp);
		var fw;

		folder.mkdir;

		s.sync;
		fw = FluidWaveform(drums,bounds:Rect(0,0,1200,300));
		s.sync;
		1.wait;
		fw.write(folder+/+"00_original_waveform.png");
		fw.close;
		s.sync;
		"original waveform saved".postln;

		s.sync;
		fw = FluidWaveform(drums,bounds:Rect(0,0,1200,300),showSpectrogram:true,showWaveform:false,spectrogramColorScheme:1);
		s.sync;
		1.wait;
		fw.write(folder+/+"00_original_spectrogram.png");
		fw.close;
		s.sync;
		"original spectrogram saved".postln;

		// process it:
		FluidBufNMF.processBlocking(s,drums,activations:activations,bases:bases,resynth:resynth,components:n_components,action:{

			fork({
				var filterbuf, exampleDur = 5, actsbuf;

				fw = FluidWaveform(resynth,bounds:Rect(0,0,1200,300));
				s.sync;
				1.wait;
				fw.write(folder+/+"00_resynth_buffer.png");
				fw.close;
				s.sync;

				fw = FluidWaveform(
					resynth,
					featureBuffer:activations,
					bounds:Rect(0,0,1200,300),
					stackFeatures:true,
					normalizeFeaturesIndependently:false
				);
				s.sync;
				1.wait;
				fw.write(folder+/+"00_resynth_buffer_with_activations.png");
				fw.close;
				s.sync;

				[[bases,"Bases"],[activations,"Activations"]].do{
					arg arr;
					var buffer = arr[0];
					var name = arr[1];
					var fw;

					fw = FluidWaveform(featureBuffer:buffer,bounds:Rect(0,0,1200,300),stackFeatures:true,normalizeFeaturesIndependently:false);
					s.sync;
					1.wait;
					fw.write(folder+/+"01_%_plot.png".format(name));
					fw.close;
					"% plot created".format(name).postln;
				};

				s.sync;

				// resynth.plot;
				// resynth.postln;

				n_components.do{
					arg i;
					FluidBufCompose.processBlocking(s,resynth,startChan:i,numChans:1,destination:dur_writeBuf);
					s.sync;
					dur_writeBuf.write(folder+/+"02_component_%.wav".format(i),"wav");
					s.sync;
				};

				"components written to wav files".postln;

				s.sync;


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
					example_dur_buf.write(folder+/+"03_base_%_filtering.wav".format(i),"wav");
				};

				s.sync;

				"filtered sound examples made".postln;

				// ============== enveloping =============================

				actsbuf = Buffer.alloc(s,drums.numFrames,n_components);

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

				"enveloping noise examples made".postln;
				"done".postln;
			},AppClock);
		});
	},AppClock);
};
)