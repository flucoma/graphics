(
var stamp = Date.localtime.stamp;
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+"%_from_analysis".format(stamp);
s.waitForBoot{
	~guitar = Buffer.read(s,FluidFilesPath("Tremblay-AaS-AcousticStrums-M.wav"),startFrame:560742,numFrames:388250);
	~nComp = 10;
	~fftSize = 1024;
	~bases = Buffer(s);
	~resynth = Buffer(s);
	~activations = Buffer(s);
	~summed_harmonic_bases = Array.fill((~fftSize/2)+1,{0});
	~pick_and_resonances = Buffer(s);

	s.sync;

	~dur_buf_for_writing = Buffer.alloc(s,~guitar.numFrames);

	~save_img = {
		arg win, path;
		var img = Image.fromWindow(win);
		img.write(path,"png",quality:100);
	};

	folder.mkdir;

	s.sync;

	FluidBufNMF.processBlocking(s,~guitar,bases:~bases,resynth:~resynth,activations:~activations,components:~nComp,windowSize:~fftSize,action:{
		"nmf complete".postln;
	});

	s.sync;

	~nComp.do{
		arg i;
		FluidBufCompose.processBlocking(s,~resynth,startChan:i,numChans:1,destination:~dur_buf_for_writing);
		~dur_buf_for_writing.write(folder+/+"00_resynth_comp_%.wav".format(i),"wav");
	};

	s.sync;

	// plot the bases
	~fw = FluidWaveform(featuresBuffer:~bases,stackFeatures:true,bounds:Rect(0,0,1600,900),normalizeFeaturesIndependently:false);
	s.sync;
	1.wait;
	~save_img.(~fw.win,folder+/+"00_6_bases.png");
	~fw.close;
	"6 bases image made".postln;

	// plot the activations
	~fw = FluidWaveform(featuresBuffer:~activations,stackFeatures:true,bounds:Rect(0,0,1600,900),normalizeFeaturesIndependently:false);
	s.sync;
	1.wait;
	~save_img.(~fw.win,folder+/+"00_6_activations.png");
	~fw.close;
	"6 activations image made".postln;

	~bases.loadToFloatArray(action:{
		arg bases_array;
		var weighted_averages;

		~bases_array = bases_array.clump(~nComp).flop;

		weighted_averages = ~bases_array.collect{
			arg base;
			base.collect{
				arg mag, i;
				mag * i;
			}.sum;
		};

		~pick_i = weighted_averages.maxIndex;
		"The basis with the highest \"spectral centroid\" is at index: %".format(~pick_i).postln;
	});

	s.sync;

	~bases_array.do{
		arg base, i;
		if(i != ~pick_i,{
			~summed_harmonic_bases = ~summed_harmonic_bases + base;
		});
	};
	~summed_harmonic_bases = ~summed_harmonic_bases / (~nComp-1);

	FluidBufCompose.processBlocking(s,~bases,startChan:~pick_i,numChans:1,destination:~pick_and_resonances);
	FluidBufCompose.processBlocking(s,Buffer.loadCollection(s,~summed_harmonic_bases),destination:~pick_and_resonances,destStartChan:1);

	s.sync;

	~fw = FluidWaveform(bounds:Rect(0,0,1600,300));
	~fw.addFeaturesLayer(~pick_and_resonances,[FluidViewer.createCatColors[~pick_i],Color.black],true,false);
	~fw.front;
	s.sync;
	1.wait;
	~save_img.(~fw.win,folder+/+"01_pick_&_resonances.png");
	~fw.close;
	"pick and res image made".postln;

	s.sync;

	~resynth = Buffer(s);

	s.sync;

	FluidBufNMF.processBlocking(s,~guitar,resynth:~resynth,bases:~pick_and_resonances,basesMode:2,components:2,action:{"nmf complete".postln;});

	s.sync;

	["pick","resonance"].do{
		arg name, i;
		FluidBufCompose.processBlocking(s,~resynth,startChan:i,numChans:1,destination:~dur_buf_for_writing);
		~dur_buf_for_writing.write(folder+/+"02_final_resynth_%_%.wav".format(i,name),"wav");
	};
	s.sync;
	"done with all".postln;
};
)