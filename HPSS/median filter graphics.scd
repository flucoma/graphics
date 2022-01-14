(
s.waitForBoot{
	var stamp, folder, rect, n, sig, filtered, interleaved;
	"hpss_functions.scd".loadRelative;
	Window.closeAll;
	stamp = Date.localtime.stamp;
	folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"median_filter_outputs/%_sine".format(stamp);
	rect = Rect(0,0,1600,400);

	n = 1000;
	sig = n.collect{arg i; sin(i.linlin(0.0,n-1,0.0,2pi))};
	3.do{
		var m = rrand(3,9);
		var rand = rrand(-1.0,1.0);
		var range = 0.02;
		var start = rrand(0,sig.size - m);
		m.do{
			arg i;
			sig[start + i] = rand + rrand(range * -1, range)
		};
	};
	2.do{
		var m = rrand(3,12);
		var start = rrand(0,sig.size - m);
		m.do{
			arg i;
			sig[start + i] = rrand(-1.0,1.0);
		};
	};

	// import form hpss graphics script
	// if(~median_filter.isNil,{"You need to get the ~median_filter function from the other file!".error;});
	filtered = ~median_filter.(sig,31);

	/*~sig.size.postln;
	~filtered.size.postln;

	~sig.plot;
	~filtered.plot;*/

	interleaved = sig.collect{
		arg val, i;
		[val,filtered[i]]
	}.flatten;

	"interleaved: %".format(interleaved).postln;

	Buffer.loadCollection(s,interleaved,2,{
		arg buf;
		buf.postln;
		fork({
			var fw = FluidWaveform(featureBuffer:buf,bounds:rect,normalizeFeaturesIndependently:false);
			folder.mkdir;

			s.sync;
			0.1.wait;

			fw.write(folder+/+"%_02_sine_disjunct_and_filtered.png".format(stamp));
			fw.close;

			"done".postln;

		},AppClock)
	});
};
)

// =============================== real sounds ===============================
// load a file to HPSS
(
s.waitForBoot{

	var snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	//var snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),startFrame:44100 * 1.157,numFrames:44100 * 0.291);
	var magbuf = Buffer(s);

	s.sync;

	"hpss_functions.scd".loadRelative;

	FluidBufSTFT.process(s,snare,magnitude:magbuf,action:{"done".postln});

	s.sync;

	magbuf.loadToFloatArray(action:{
		arg mags;
		var frame_100_bins, filtered, interleaved, freq_slice, freq_slice_filtered, freq_slice_interleaved;
		mags = mags.clump(magbuf.numChannels).flop;

		"mags shape: %".format(mags.shape).postln;

		// VERTICAL SLICE, CREATING A PERCUSSIVE ENHANCED THING
		frame_100_bins = mags.flop[3][..99];

		filtered = ~median_filter.(frame_100_bins,31);

		interleaved = frame_100_bins.collect{
			arg val, i;
			[val,filtered[i]]
		}.flatten;

		Buffer.loadCollection(s,~interleaved,2,{
			arg buf;
			buf.postln;
			FluidWaveform(featureBuffer:buf,bounds:Rect(0,0,1600,400),normalizeFeaturesIndependently:false);
		});

		// A HORIZONTAL SLICE, CREATING A HARMONICAL ENHANCED THING

		freq_slice = mags[13];
		freq_slice_filtered = ~median_filter.(freq_slice,17);

		freq_slice_interleaved = freq_slice.collect{
			arg val, i;
			[val,freq_slice_filtered[i]]
		}.flatten;

		Buffer.loadCollection(s,freq_slice_interleaved,2,{
			arg buf;
			buf.postln;
			FluidWaveform(featureBuffer:buf,bounds:Rect(0,0,1600,400),normalizeFeaturesIndependently:false);
		});

	});
}
)