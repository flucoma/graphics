(
s.options.sampleRate_(44100);
s.waitForBoot{
	var start = 352068;
	var end = 390016;
	var num = end - start;
	var buf = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),start,num);
	// var buf = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	var databuf, win, sfv, path, bounds, lineWidth = 2;

	var colors = "1f77b4ff7f0e2ca02cd627289467bd8c564be377c27f7f7fbcbd2217becf".clump(6).collect{
		arg six;
		Color(*six.clump(2).collect{
			arg two;
			"0x%".format(two).interpret / 255;
		});
	};

	s.sync;

	databuf = Buffer.alloc(s,buf.numFrames / s.options.blockSize,3);

	s.sync;

	{
		var sig = PlayBuf.ar(1,buf,doneAction:2);
		var sd = SampleDur.ir;
		var amp = Amplitude.kr(sig);
		var fast = amp.lag(0.2);
		var slow = amp.lag(0.5);
		RecordBuf.kr([fast,slow,fast-slow],databuf,loop:0,doneAction:2);
		// RecordBuf.kr(slow,slowbuf,loop:0,doneAction:2);
	}.play;

	buf.duration.wait;

	s.sync;

	databuf.loadToFloatArray(action:{
		arg data;
		var fast, slow, diff, min = inf, max = -inf;

		data.do({
			arg val;
			if(val < min,{min = val});
			if(val > max,{max = val});
		});

		data = (data - min) / (max - min);

		data = data.clump(3).flop;

		data.postln;

		fast = data[0];
		slow = data[1];
		diff = data[2];


		path = "%%_%_FluidWaveform.wav".format(PathName.tmp,Date.localtime.stamp,UniqueID.next);
		bounds = Rect(50,400,1600,400);

		win = Window("FluidWaveform",bounds);
		buf.write(path,"wav");

		s.sync;

		sfv = SoundFileView(win,Rect(0,0,bounds.width,bounds.height));
		sfv.peakColor_(Color(*0.8.dup(3)));
		// sfv.rmsColor_(Color.black);
		sfv.rmsColor_(Color.clear);
		sfv.background_(Color.white);
		sfv.readFile(SoundFile(path));
		sfv.gridOn_(false);

		UserView(win,Rect(0,0,bounds.width,bounds.height))
		.drawFunc_({
			Pen.width_(lineWidth);
			[fast,slow,diff].do{
				arg chan, j;
				chan = chan.resamp1(bounds.width).linlin(0,1,bounds.height,0);
				Pen.moveTo(Point(0,chan[0]));
				chan[1..].do{
					arg val, i;
					Pen.lineTo(Point(i+1,val));
				};
				Pen.color_(colors[j]);
				Pen.stroke;
			};
		});

		win.front;

		File.delete(path);
	});
};
)

FluidAmpSlice