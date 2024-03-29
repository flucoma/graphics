(
s.options.inDevice_("MacBook Pro Microphone");
// s.options.outDevice_("MacBook Pro Speakers");
s.options.outDevice_("External Headphones");
s.options.sampleRate_(44100);
s.waitForBoot{
	var start = 352068;
	var end = 390016;
	var num = end - start;
	var buf = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),start,num);
	// var buf = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	var databuf, stamp = Date.localtime.stamp;

	var outfolder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"outputs"+/+stamp;

	var colors = "1f77b4ff7f0e2ca02cd627289467bd8c564be377c27f7f7fbcbd2217becf".clump(6).collect{
		arg six;
		Color(*six.clump(2).collect{
			arg two;
			"0x%".format(two).interpret / 255;
		});
	};

	outfolder.mkdir;

	s.sync;

	databuf = Buffer.alloc(s,buf.numFrames / s.options.blockSize,2);

	s.sync;

	{
		var sig = PlayBuf.ar(1,buf,doneAction:2);
		var sd = SampleDur.ir;
		var amp = Amplitude.kr(sig);
		/*		var fast = amp.lag(0.2);
		var slow = amp.lag(0.5);*/
		var fast = LagUD.kr(amp,0.2,0.1);
		var slow = LagUD.kr(amp,0.5,0.6);
		RecordBuf.kr([fast,slow],databuf,loop:0,doneAction:2);
		// RecordBuf.kr(slow,slowbuf,loop:0,doneAction:2);
	}.play;

	buf.duration.wait;
	0.1.wait;

	s.sync;

	"buf recorded".postln;

	databuf.loadToFloatArray(action:{
		arg data;
		var fast, slow, diff, diff2, min = inf, max = -inf;

		data.do({
			arg val;
			if(val < min,{min = val});
			if(val > max,{max = val});
		});

		data = (data - min) / (max - min);

		data = data.clump(2).flop;

		data.postln;
		data.shape.postln;

		fast = data[0];
		slow = data[1];
		diff = data[0] - data[1];
		diff2 = data[1] - data[0];

		[[fast,slow],[fast,slow,diff]].do{
			arg plotthese, img_i;
			var win, sfv, path, bounds, lineWidth = 2, img;

			path = "%%_%_FluidWaveform.wav".format(PathName.tmp,Date.localtime.stamp,UniqueID.next);

			path.postln;

			bounds = Rect(50,400,1600,400);

			win = Window("FluidWaveform",bounds);
			buf.write(path,"wav");

			s.sync;

			sfv = SoundFileView(win,Rect(0,0,bounds.width,bounds.height));
			sfv.peakColor_(Color(*0.8.dup(3)));
			// sfv.rmsColor_(Color.black);
			sfv.rmsColor_(Color.clear);
			sfv.drawsBoundingLines_(false);
			sfv.background_(Color.white);
			sfv.readFile(SoundFile(path));
			sfv.gridOn_(false);

			s.sync;

			File.delete(path);

			UserView(win,Rect(0,0,bounds.width,bounds.height))
			.drawFunc_({
				Pen.width_(lineWidth);
				plotthese.do{
					arg chan, j;
					if(chan.notNil,{
						chan = chan.resamp1(bounds.width).linlin(0,1,bounds.height,0);
						Pen.moveTo(Point(0,chan[0]));
						chan[1..].do{
							arg val, i;
							Pen.lineTo(Point(i+1,val));
						};
						Pen.color_(colors[j]);
						Pen.stroke;
					})
				};
			});

			win.front;

			s.sync;

			img = Image.fromWindow(win);

			s.sync;

			//img.plot;
			img.write(outfolder+/+"%_%_ampslice.png".format(stamp,img_i),quality:100);
			win.close;
		};
	});
};
)