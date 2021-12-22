(
s.waitForBoot{
	~drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	~bases = Buffer(s);
	~activations = Buffer(s);
	~n_components = 3;
	// process it:
	FluidBufNMF.processBlocking(s,~drums,activations:~activations,bases:~bases,resynth:~resynth,components:~n_components,action:{

		~stamp = Date.localtime.stamp;
		[[~bases,"Bases"],[~activations,"Activations"]].do{
			arg arr;
			var buffer = arr[0];
			var name = arr[1];
			arr.postln;
			buffer.loadToFloatArray(action:{
				arg buffer_contents;
				var win, comp, plot, img;
				buffer_contents = buffer_contents.clump(~n_components).flop;
				fork({
					win = Window("Bases", Rect(200, 200, 1400, 600));
					comp = CompositeView(win, Rect(0, 0, win.bounds.width, win.bounds.height));
					plot = Plotter("plot", parent: comp).value_(buffer_contents);
					win.front;
					// img = Image.fromWindow(win);
					//img.write("/Users/macprocomputer/Desktop/_flucoma/code/graphics/BufNMF/%_%.png".format(~stamp,name),quality:100);
					win.close;
				},AppClock)
			});
		};
		"done".postln;
	});
};
)

// you may have guessed that it would separate out the three components into: (1) snare, (2) hihat, and (3) kick
// and it might have worked! but it may not have, and it won't provide the same result every time because it
// starts each process from a stochastic state (you can seed this state if you want...see below).

// ====== ok so what is it doing? ========

// first, let's make two new buffers called...
~bases = Buffer(s);
~activations = Buffer(s);

// and we'll explicitly pass these into the process
FluidBufNMF.processBlocking(s,~drums,bases:~bases,activations:~activations,resynth:~resynth,components:2,action:{"done".postln;});

// now we can plot them (because this process starts from a stochastic state, your results may vary!):
~bases.plot("bases");
// the bases are a like a spectral template that FluidBufNMF has found in the source buffer
// in one you should see one spectrum that resembles a snare spectrum (the resonant tone of the snare
// in the mid range) and another that resembles the kick + hihat we heard earlier (a large peak in the very
// low register and some shimmery higher stuff)

~activations.plot("activations");
// the activations are the corresponding loudness envelope of each base above. It should like an amplitude
// envelope follower of the drum hits in the corresponding bases.

// FluidBufNMF then uses the individual bases with their corresponding activations to resynthesize the sound of just
// component.
// the buffer passed to `resynth` will have one channel for each component you've requested

~resynth.numChannels
~resynth.play;

// ======== to further understand NMF's bases and activations, consider one more object: FluidNMFFilter ==========
// FluidNMFFilter will use the bases (spectral templates) of a FluidBufNMF analysis to filter (i.e., decompose) real-time audio

// for example, if we use the bases from the ~drums analysis above, it will separate the snare from the kick & hihat like before
// this time you'll hear one in each stereo channel (again, results may vary)

(
{
	var src = PlayBuf.ar(1,~drums,BufRateScale.ir(~drums),doneAction:2);
	var sig = FluidNMFFilter.ar(src,~bases,2);
	sig;
}.play;
)

// if we play a different source through FluidNMFFilter, it will try to decompose that real-time signal according to the bases
// it is given (in our case the bases from the drum loop)
~song = Buffer.readChannel(s,FluidFilesPath("Tremblay-beatRemember.wav"),channels:[0]);

(
{
	var src = PlayBuf.ar(1,~song,BufRateScale.ir(~song),doneAction:2);
	var sig = FluidNMFFilter.ar(src,~bases,2);
	sig;
}.play;
)

// what gets "NMF Filtered" to the left? to the right? how do they resemble the bases from the drum loop?

// ========= the activations could also be used as an envelope through time ===========
(
{
	var activation = PlayBuf.ar(2,~activations,BufRateScale.ir(~activations),doneAction:2);
	var sig = WhiteNoise.ar(0.dbamp) * activation;
	sig;
}.play;
)

// note that the samplerate of the ~activations buffer is not a usual one...
~activations.sampleRate
// this is because each frame in this buffer doesn't correspond to one audio sample, but instead to one
// hopSize, since these values are derived from an FFT analysis
// so it is important to use BufRateScale (as seen above) in order to make sure they play back at the
// correct rate

// if we control the amplitude of the white noise *and* send it through FluidNMFFilter, we'll get something
// somewhat resembles both the spectral template and loudness envelope of the bases of the original
// (of course it's also good to note that the combination of the *actual* bases and activations is how
// FluidBufNMF creates the channels in the resynth buffer which will sound much better than this
// filtered WhiteNoise version)
(
{
	var activation = PlayBuf.ar(2,~activations,BufRateScale.ir(~activations),doneAction:2);
	var sig = WhiteNoise.ar(0.dbamp);
	sig = FluidNMFFilter.ar(sig,~bases,2) * activation;
	sig;
}.play;
)