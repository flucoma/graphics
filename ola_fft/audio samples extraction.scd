(
~path = "/Users/macprocomputer/Desktop/_flucoma/code/flucoma-core-src/AudioFiles/Nicol-LoopE-M.wav";
SoundFile.use(~path,{
	arg sf;
	var array = FloatArray.newClear(sf.numFrames * sf.numChannels);
	sf.readData(array);
	ArrayToCSV(array,"/Users/macprocomputer/Desktop/_flucoma/code/graphics/ola fft/%_samples_%.csv".format(PathName(~path).fileName,Date.localtime.stamp));
	"done".postln;
});
)

(
Routine{
	var buf = Buffer.read(s,~path);
	var features = Buffer(s);
	s.sync;
	FluidBufPitch.process(s,buf,features:features,windowSize:1024,hopSize:512,action:{
		features.numFrames.postln;
		"done".postln;
	});
}.play;
)