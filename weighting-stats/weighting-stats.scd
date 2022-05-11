//load a part of a sound that has 3 clear components: a clear pitch component to start, a noisy pitchless ending and DC offset silence on both ends
(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
var savefw = {
	arg fw, name, close = true;
	var img;
	1.wait;
	img = Image.fromWindow(fw.parent);
	img.write(outfolder+/+name,"png",100);
	fw.parent.close;
};
s.waitForBoot{
	var src = Buffer.read(s,FluidFilesPath("Tremblay-ASWINE-ScratchySynth-M.wav"),0,44100 * 6);
	var pitch_analysis = Buffer(s);

	var stats = Buffer(s);
	var loud = Buffer(s);
	var scaled = Buffer(s);
	var conf = Buffer(s);
	var threshed = Buffer(s);
	var pitch = Buffer(s);
	var sine_rec_buf;
	var brutePitchStats = Array.new;
	var loudnessWeighedPitchStats = Array.new;
	var confidenceWeighedPitchStats = Array.new;
	var condidenceWeightedPitchIQRStats = Array.new;
	var pitchIQRStats = Array.new;
	var mean_freq;
	var thresh;
	var outliersCutoff;

	s.sync;

	sine_rec_buf = Buffer.alloc(s,src.numFrames);

	outfolder.mkdir;

	// consider trying to extract the pitch from this recording

	savefw.(FluidWaveform(src,bounds:Rect(0,0,1600,400)),"02_src.png");

	src.write(outfolder+/+"01_src.wav","wav","int24",);

	// a quick look at the pitch analysis shows a quite eratic time series

	FluidBufPitch.processBlocking(s,src,features:pitch_analysis);
	FluidBufCompose.processBlocking(s,pitch_analysis,numChans:1,destination:pitch);
	FluidBufCompose.processBlocking(s,pitch_analysis,startChan:1,numChans:1,destination:conf);
	savefw.(FluidWaveform(src,featuresBuffer:pitch,stackFeatures:true,bounds:Rect(0,0,1600,400)),"03_src_with_pitch.png");

	// if one were to simply take the average pitch from this time series you get _________ but it doesn't sound right;

	FluidBufStats.processBlocking(s,pitch,stats:stats);
	stats.loadToFloatArray(action:{
		arg fa;
		mean_freq = fa[0].postln;
		{
			var sig = SinOsc.ar(mean_freq,0,-20.dbamp);
			var srcsig = PlayBuf.ar(1,src,BufRateScale.ir(src));
			var env = EnvGen.kr(Env([0,1,1,0],[0.03,src.duration-0.06,0.03]),doneAction:2);
			sig = sig + srcsig;
			sig = sig * env;
			RecordBuf.ar(sig,sine_rec_buf,loop:0);
			sig.dup;
		}.play;
	});

	s.sync;

	src.duration.wait;
	1.wait;

	sine_rec_buf.write(outfolder+/+"04_meanFreq=%.wav".format(mean_freq.round),"wav");
	s.sync;


	// but one can see that during the moments of clear sustained tone, the pitch confidence is quite high and the pitch analysis is quite stable.

	savefw.(FluidWaveform(src,featuresBuffer:pitch_analysis,stackFeatures:true,bounds:Rect(0,0,1600,400)),"05_src_with_pitch_and_conf.png");

	// we'll use the pitch confidence to weight the statistical analysis so our mean will be a weighted mean based on how confident the pitch algorithm is in the pitch it is returning;
	FluidBufStats.processBlocking(s,pitch,stats:stats,weights:conf);

	stats.loadToFloatArray(action:{
		arg fa;
		mean_freq = fa[0].postln;
		{
			var sig = SinOsc.ar(mean_freq,0,-20.dbamp);
			var srcsig = PlayBuf.ar(1,src,BufRateScale.ir(src));
			var env = EnvGen.kr(Env([0,1,1,0],[0.03,src.duration-0.06,0.03]),doneAction:2);
			sig = sig + srcsig;
			sig = sig * env;
			RecordBuf.ar(sig,sine_rec_buf,loop:0);
			sig.dup;
		}.play;
	});

	s.sync;

	src.duration.wait;
	1.wait;

	sine_rec_buf.write(outfolder+/+"06_meanFreqWeighted=%.wav".format(mean_freq.round),"wav");
	s.sync;

	// now it's too low, how about we threshold the conf at __________
	thresh = 0.97;
	FluidBufThresh.processBlocking(s,conf,destination:threshed,threshold:thresh);
	FluidBufStats.processBlocking(s,pitch,stats:stats,weights:threshed);

	stats.loadToFloatArray(action:{
		arg fa;
		mean_freq = fa[0].postln;
		{
			var sig = SinOsc.ar(mean_freq,0,-20.dbamp);
			var srcsig = PlayBuf.ar(1,src,BufRateScale.ir(src));
			var env = EnvGen.kr(Env([0,1,1,0],[0.03,src.duration-0.06,0.03]),doneAction:2);
			sig = sig + srcsig;
			sig = sig * env;
			RecordBuf.ar(sig,sine_rec_buf,loop:0);
			sig.dup;
		}.play;
	});

	s.sync;

	src.duration.wait;
	1.wait;

	FluidBufCompose.processBlocking(s,threshed,destination:pitch_analysis,destStartChan:1);
	s.sync;
	savefw.(FluidWaveform(src,featuresBuffer:pitch_analysis,stackFeatures:true,bounds:Rect(0,0,1600,400)),"07_src_with_pitch_and_threshed.png");


	sine_rec_buf.write(outfolder+/+"08_thresh=%_meanFreqWeighted=%.wav".format(thresh,mean_freq.round),"wav");
	s.sync;

	// much more accurate!
}
)

// FluidBufPitch.process(s,b,features: ~pitch_analysis)
// FluidBufStats.process(s,~pitch_analysis,stats:~stats)
// ~stats.getn(0,14,{|x|~brutePitchStats = x; x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
//
// //observe the data - there are something clearly "wrong" in there - mostly, should we consider the stats on pitch when the confidence is low?
// ~pitch_analysis.plot(separately: true)
//
// //let's check the loudness
// FluidBufLoudness.process(s,b,features: ~loud)
// FluidBufStats.process(s,~loud,stats:~stats)
// ~stats.getn(0,14,{|x|x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
//
// ~loud.plot(separately: true)
//
// //it seems the loudness of the noisy section will not help us reject the silence. But let's try
// FluidBufScale.process(s,~loud,numChans: 1,destination: ~scaled,inputLow: -60,inputHigh: -20)
// FluidBufStats.process(s,~pitch_analysis, stats:~stats,weights: ~scaled)
// ~stats.getn(0,14,{|x|~loudnessWeighedPitchStats = x; x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
// //not much difference but let's listen
//
// //average pitch
// c = {SinOsc.ar(~brutePitchStats[0],mul: 0.05)}.play
// //compare with the source
// b.play
// c.free
// //loudness-weighted average
// c = {SinOsc.ar(~loudnessWeighedPitchStats[0],mul: 0.05)}.play
// //compare with the source
// b.play
// c.free
// //hmmm, worse! That is because we did remove the low amplitude skewing to wards the default value (high) which was balancing our noisy peak with low pitch and low pitch confidence...
//
// //let's instead weight against the pitch confidence, first applying a threshold to so we pull down any middle value we want to ignore
// FluidBufThresh.process(s, ~pitch_analysis, startChan: 1, numChans: 1, destination: ~scaled, threshold: 0.8)
// FluidBufStats.process(s,~pitch_analysis, stats:~stats,weights: ~scaled)
// ~stats.getn(0,14,{|x|~confidenceWeighedPitchStats = x;x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
//
// //let's listen
// c = {SinOsc.ar(~confidenceWeighedPitchStats[0],mul: 0.05)}.play
// //compare with the source
// b.play
// c.free
// // much better! it is even better when we move the threshold above but 0.8 confidence is quite high...  If we look at our stats we see that there are still minima in the low hundreds, and maxima in the very top...These must be statistically far enough and few enough just to mess a bit our stats, so let's use the inter-quantile range to first remove them then compute the stats.
// FluidBufStats.process(s,~pitch_analysis, stats:~stats,weights: ~scaled,outliersCutoff: 1.5)
// ~stats.getn(0,14,{|x|~confidenceWeightedPitchIQRStats = x;x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
// //now that is impressive!
// c = {SinOsc.ar(~confidenceWeightedPitchIQRStats[0],mul: 0.05)}.play
// b.play
// c.free
//
// //for completion, here is just with rejection of outliers - not as good, but a decent second best!
// FluidBufStats.process(s,~pitch_analysis, stats:~stats,outliersCutoff: 1.5)
// ~stats.getn(0,14,{|x|~pitchIQRStats = x;x.reshape(7,2).do{|y| "%\t\t\t%\n".postf(y[0].round(0.1),y[1].round(0.01))}})
// c = {SinOsc.ar(~pitchIQRStats[0],mul: 0.05)}.play
// b.play
// c.free
