(
~drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));// first, let's make two new buffers called...
~bases = Buffer(s);
~activations = Buffer(s);
~n_components = 3;
FluidBufNMF.processBlocking(s,~drums,bases:~bases,activations:~activations,components:~n_components,action:{"done".postln;});
)

~rec_buf = Buffer.alloc(s,~drums.numFrames / s.options.blockSize,~n_components);

(
{
	var sig = PlayBuf.ar(1,~drums,BufRateScale.kr(~drums),doneAction:2);
	var match = FluidNMFMatch.kr(sig,~bases,~n_components).poll;
	RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
}.play;
)

~fw = FluidWaveform(~drums,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:true,waveformColor:Color(*0.9.dup(3)));

~img = Image.fromWindow(~fw.win);

~img.plot;

~img.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"%_nmf_match.png".format(Date.localtime.stamp),quality:100);

//=========================================================================

~song = Buffer.read(s,FluidFilesPath("Tremblay-beatRemember.wav"));

~rec_buf = Buffer.alloc(s,~song.numFrames / s.options.blockSize,~n_components);

(
{
	var sig = PlayBuf.ar(1,~song,BufRateScale.kr(~song),doneAction:2);
	var match = FluidNMFMatch.kr(sig,~bases,~n_components).poll;
	RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
}.play;
)

~fw = FluidWaveform(~song,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:true,waveformColor:Color(*0.9.dup(3)));

~img = Image.fromWindow(~fw.win);

~img.plot;

~img.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"%_nmf_match.png".format(Date.localtime.stamp),quality:100);

//==============================================================================================================

~rec_buf = Buffer.alloc(s,~song.numFrames,3);

(
{
	var sig = PlayBuf.ar(1,~song,BufRateScale.kr(~song),doneAction:2);
	var match = FluidNMFFilter.ar(sig,~bases,~n_components).poll;
	RecordBuf.ar(match,~rec_buf,loop:0,doneAction:2);
}.play;
)

~mono_buf = Buffer.alloc(s,~song.numFrames);

(
~n_components.do{
	arg i;
	FluidBufCompose.processBlocking(s,~rec_buf,startChan:i,numChans:1,destination:~mono_buf);
	~mono_buf.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"%_song_component_%.wav".format(Date.localtime.stamp,i+1),"wav");
};
)

//=================================== dog ===================================

// FluidNMFMatch can be trained on a small section of audio and then used to identify whenever similar audio
// appears again in the whole file or other files

// for example, take this 22 second field recording that has _some_ dog barking in it
~golcar = Buffer.readChannel(s,FluidFilesPath("Tremblay-BaB-SoundscapeGolcarWithDog.wav"),channels:[0]);

~golcar4s = Buffer.readChannel(s,FluidFilesPath("Tremblay-BaB-SoundscapeGolcarWithDog.wav"),numFrames:~golcar.sampleRate * 4,channels:[0])

~golcar.play;

// we'll do a FluidBufNMF analysis on just the first 4 seconds (the part that has some dog bark in it);
~bases = Buffer(s);
~activations = Buffer(s);
~resynth = Buffer(s);
FluidBufNMF.processBlocking(s,~golcar4s,bases:~bases,activations:~activations,resynth:~resynth,components:2,action:{"done".postln;});

~mono_buf = Buffer.alloc(s,~golcar4s.numFrames);

(
2.do{
	arg i;
	FluidBufCompose.processBlocking(s,~resynth,startChan:i,numChans:1,destination:~mono_buf);
	~mono_buf.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"%_golcar4s_component_%.wav".format(Date.localtime.stamp,i+1),"wav");
};
)

~fw = FluidWaveform(featureBuffer:~bases,bounds:Rect(0,0,1200,300),stackFeatures:true);
~fw = FluidWaveform(~golcar4s,featureBuffer:~activations,bounds:Rect(0,0,1200,300),stackFeatures:true);

~img = Image.fromWindow(~fw.win);
~img.plot;
~img.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"%_nmf_match.png".format(Date.localtime.stamp),quality:100);


// and then play the whole 22 second sound file through FluidNMFMatch to see where in the sound file the spectral template
// of the dog bark is found. because the FluidBufNMF analysis starts from a stochastic state, we can't be sure which base
// contains the dog bark, but watching the green bars in this window will make very clear which one is detecting where
// in the sound file a dog bark is found

~rec_buf = Buffer.alloc(s,~golcar.numFrames / s.options.blockSize,2);

(
Task({
	var match = [0,0]; // an array for storing the output of FluidNMFMatch
	var win = Window("FluidNMFMatch",Rect(0,0,200,400));
	var uv = UserView(win,win.bounds)
	.drawFunc_{
		var w = uv.bounds.width / 2;
		Pen.color_(Color.green);
		match.do{ // iterate over the two values in the match array that are taken from FluidNMFMatch
			arg match_val, i;
			var match_norm = match_val.linlin(0,30,0,uv.bounds.height); // make it a height appropriate for the window
			var top = uv.bounds.height - match_norm; // offset from the top so it looks like it's a bar rising from the bottom
			/*top.postln;*/
			Pen.addRect(Rect(i * w,top,w,match_norm)); // draw the rect
			Pen.draw;
		};
	};

	{
		var sig = PlayBuf.ar(1,~golcar,BufRateScale.ir(~golcar),doneAction:2); // play the whole sound file
		var match = FluidNMFMatch.kr(sig,~bases,2);
		RecordBuf.kr(match,~rec_buf,loop:0,doneAction:2);
		// 30 times per second send the output of FluidNMFMatch to the language
		SendReply.kr(Impulse.kr(30),"/nmfmatch",match);
		sig;
	}.play;

	OSCdef(\nmfmatch,{ // catch the output of FluidNMFMatch in the language
		arg msg;
		match = msg[3..]; // populate the array that is used for plotting
		{uv.refresh}.defer; // and then refresh the window
	},"/nmfmatch");

	win.front;

},AppClock).play;
)

~fw = FluidWaveform(~golcar,featureBuffer:~rec_buf,bounds:Rect(0,0,1200,300),stackFeatures:false);