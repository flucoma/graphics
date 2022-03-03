(
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+"%_seeding_activations_piano".format(Date.localtime.stamp);
s.waitForBoot{
	var notedur = 1;
	// var src = Buffer.alloc(s,s.sampleRate * 8 * notedur);
	var src = Buffer.read(s,"outputs/220216_104616/00_saw_scale.wav".resolveRelative);
	var freqs = Buffer.loadCollection(s,([0,2,4,5,7,9,11,12] + 60).midicps);
	var bases = Buffer(s);
	var fw, img;
	var piano = Buffer.readChannel(s,"somewhere-over-the-rainbow/somewhere-over-the-rainbow.wav".resolveRelative,channels:[0]);
	var resynth = Buffer(s);
	var linearized_buf = Buffer(s);
	var activations, hopSize = 512;
	var buffer_of_ones;
	var empty_activations = Buffer(s);
	var linewidth = 2;

	s.sync;

	activations = Buffer.alloc(s,(piano.numFrames / hopSize) + 1,8);

	s.sync;

	buffer_of_ones = Buffer.loadCollection(s,Array.fill((activations.numFrames / 8).floor,{1}));

	s.sync;

	8.do{
		arg i;
		FluidBufCompose.processBlocking(s,buffer_of_ones,destination:activations,destStartFrame:i * buffer_of_ones.numFrames,destStartChan:i);
	};

	s.sync;

	// activations.plot;

	"activations numFrames:   %".format(activations.numFrames).postln;
	"activations numChannels: %".format(activations.numChannels).postln;
	((piano.numFrames / hopSize) + 1).postln;

	/*{
	var freq = Index.kr(freqs,PulseCount.kr(Impulse.kr(notedur.reciprocal))-1);
	var sig = LFSaw.ar(freq) * -30.dbamp;
	RecordBuf.ar(sig,src,loop:0,doneAction:2);
	sig;
	Silence.ar;
	}.play;

	(notedur * 9).wait;*/

	folder.mkdir;

	fw = FluidWaveform(featuresBuffer:activations,bounds:Rect(0,0,800,800),stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:linewidth).front;
	s.sync;
	1.wait;
	img = Image.fromWindow(fw.win);
	img.write(folder+/+"00_activation_seeds.png","png",100);
	fw.close;

	//	src.write(folder+/+"00_saw_scale.wav","wav");
	//
	// "saw scale written".postln;

	FluidBufNMF.processBlocking(s,src,bases:bases,activations:activations,components:8,actMode:1);

	s.sync;

	fw = FluidWaveform(featuresBuffer:activations,bounds:Rect(0,0,800,800),stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:linewidth).front;
	s.sync;
	1.wait;
	img = Image.fromWindow(fw.win);
	img.write(folder+/+"01_saw_scale_activations_(after_seeding).png","png",100);
	fw.close;

	fw = FluidWaveform(featuresBuffer:bases,bounds:Rect(0,0,800,800),stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:linewidth);
	s.sync;
	1.wait;
	img = Image.fromWindow(fw.win);
	img.write(folder+/+"02_saw_scale_bases_(after_seeding).png","png",100);
	fw.close;

	FluidBufNMF.processBlocking(s,piano,resynth:resynth,bases:bases,activations:empty_activations,basesMode:2,components:bases.numChannels);
	s.sync;

	fw = FluidWaveform(resynth,featuresBuffer:empty_activations,bounds:Rect(0,0,800,800),stackFeatures:true,normalizeFeaturesIndependently:false,lineWidth:linewidth);
	s.sync;
	1.wait;
	img = Image.fromWindow(fw.win);
	img.write(folder+/+"03_piano_decomposed_(seeded_bases_seeded_activation).png","png",100);
	fw.close;

	bases.numChannels.do{
		arg i;

		FluidBufCompose.processBlocking(s,resynth,startChan:i,numChans:1,destination:linearized_buf,destStartFrame:i*(resynth.numFrames+s.sampleRate));

		/*		{
		PlayBuf.ar(bases.numChannels,resynth)[i].dup;
		}.play;
		resynth.duration.wait;
		1.wait;*/
	};

	linearized_buf.write(folder+/+"04_components_linear_(seeded_bases_seeded_activation).wav","wav");

	"done".postln;

};
)