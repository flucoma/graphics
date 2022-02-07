(
s.waitForBoot{
	var nMels = 40, win, mels_msv, mfccs_msv, nMFCCs = 13, plotw = 800, ploth = 400, uv, margin = 4;
	var mfccs = Array.fill(nMFCCs,{0});
	var mel_disp_max = 1;
	var cos_freq_sl, invbut;
	var dispx, button_w = 40;
	var n_cos_freq_buts = 13;
	var sfv, pumitems;
	var melbuf = Buffer(s);
	var melarray, sfvpum;
	var mfccbuf = Buffer(s), mfccarray;
	var show_cosines = false;

	var set_mel_shape = {
		arg cos_freq, inv_boolean;
		Array.fill(nMels,{
			arg i;
			var x = (((2 * i) + 1) * pi) / (2 * nMels);
			var y = (x * cos_freq).cos;
			if(inv_boolean,{y = y * -1});
			y;
		});
	};

	var dct = {
		arg values, n_mfccs;
		var out;
		var nMels = values.size;
		out = n_mfccs.collect{
			arg k;
			var scale;
			var v = values.collect{
				arg xn, n;
				var x = (((2 * n) + 1) * pi * k) / (2 * nMels);
				var c = cos(x) * xn;
				c;
			}.sum;
			if(k==0) {scale = (1/(4 *nMels)).sqrt} {scale = (1/(2 *nMels)).sqrt};
			v * 2 * scale
		};
		out;
	};

	Window.closeAll;
	win = Window("MFCCs",Rect(50,200,plotw * 2, (ploth * 2) + 40));

	StaticText(win,Rect(0,0,250,20)).string_("MelFreq Spectrum Shape (Cos Freq):");

	dispx = 250;
	n_cos_freq_buts.do{
		arg i;
		var val = i;
		Button(win,Rect(dispx,0,button_w,20))
		.states_([[val.asString]])
		.action_{
			cos_freq_sl.valueAction_(val);
		};
		dispx = dispx + button_w
	};

	cos_freq_sl = EZSlider(win,Rect(dispx,0,400,20),"Cos Freq:",ControlSpec(0,12),{
		arg sl;
		mels_msv.valueAction_(set_mel_shape.(sl.value,invbut.value.asBoolean).linlin(-1,1,0,mel_disp_max));
	});

	dispx = dispx + 400;

	invbut = Button(win,Rect(dispx,0,100,20))
	.states_([["Not Inverted"],["Inverted"]])
	.action_{
		arg but;
		mels_msv.valueAction_(set_mel_shape.(cos_freq_sl.value,but.value.asBoolean).linlin(-1,1,0,mel_disp_max));
	};

	dispx = dispx + 100;

	Button(win,Rect(dispx,0,100,20))
	.states_([["No Cosines"],["With Cosines"]])
	.action_{
		arg but;
		show_cosines = but.value.asBoolean;
		win.refresh;
	};

	mels_msv = MultiSliderView(win,Rect(0,20,plotw,ploth))
	.size_(nMels)
	.drawRects_(true)
	.drawLines_(true)
	.strokeColor_(Color.blue)
	.isFilled_(true)
	.elasticMode_(true)
	.action_{
		arg msv;
		mfccs = dct.(msv.value.linlin(0,mel_disp_max,-1,1),nMFCCs);

		mfccs_msv.value_(mfccs.linlin(-40,40,0,1));

		uv.refresh;
	};

	mfccs_msv = MultiSliderView(win,Rect(plotw,20,plotw,ploth))
	.size_(nMFCCs)
	.drawRects_(true)
	.isFilled_(true)
	.drawLines_(false)
	.elasticMode_(true)
	.reference_(0.5.dup(nMFCCs))
	.action_{
		arg mfccs_user_input;
		var cosines, mels_;

		mfccs = mfccs_user_input.value.linlin(0,1,-40,40);

		// calc what the mels would look like:
		cosines = mfccs.collect{
			arg amp, j;
			var cosine;
			cosine = set_mel_shape.(j,false).collect{
				arg y, i;
				y * amp * 40.reciprocal;
			};
			cosine;
		};

		mels_ = cosines.sum.linlin(-1,1,0,mel_disp_max);
		mels_.postln;
		mels_msv.value_(mels_);

		win.refresh;
	};

	uv = UserView(win,Rect(0,20,plotw * 2,ploth))
	.acceptsMouse_(false)
	.drawFunc_{
		var melw = plotw / nMels;
		var mfccw = plotw / nMFCCs;
		Pen.stringAtPoint("MelFrequency Spectrum --- MelBand:",margin@margin);
		nMels.do{
			arg i;
			var x = i*melw;
			Pen.stringCenteredIn(i.asString,Rect(x,margin+20,melw,20));
		};

		Pen.stringAtPoint("Mel-Frequency Cepstral Coefficients:",Point((plotw) + margin,margin));
		nMFCCs.do{
			arg i;
			var x = (i*mfccw) + margin + (plotw);
			Pen.stringCenteredIn(i.asString,Rect(x,margin+20,mfccw,20));
		};

		mfccs.do{
			arg coeff, i;
			var x = (i*mfccw) + margin + (plotw);
			Pen.stringCenteredIn(coeff.round(0.01).asString,Rect(x,margin+40,mfccw,20));
		};

		if(show_cosines,{
			mfccs.do{
				arg amp, j;
				set_mel_shape.(j,false).do{
					arg y, i;
					var xpos = (melw/2) + (i*melw);
					var ypos = (ploth/2) + (y*amp*4 * -1); // -1 is to flip the y axis as the display is from the top left
					if(i == 0,{
						Pen.moveTo(Point(xpos,ypos));
					},{
						Pen.lineTo(Point(xpos,ypos));
					});
				};
				Pen.strokeColor_(FluidViewer.createCatColors[j % 10]);
				Pen.stroke;
			}
		})
	};

	pumitems = PathName(FluidFilesPath()).files.select{arg pn; pn.extension == "wav"};

	sfvpum = PopUpMenu(win,Rect(0,ploth+20,200,20))
	.items_(pumitems.collect{arg pn; pn.fileName})
	.action_{
		arg pum;
		var path = pumitems[pum.value].fullPath;
		var sf = SoundFile.openRead(path);
		sfv.soundfile_(sf);
		sfv.read(0,sf.numFrames);
		sfv.refresh;
		Buffer.readChannel(s,path,channels:[0],action:{
			arg buf;
			FluidBufMelBands.processBlocking(s,buf,features:melbuf,action:{
				FluidBufMFCC.processBlocking(s,buf,features:mfccbuf,action:{
					melbuf.loadToFloatArray(action:{
						arg mels;

						// mels = mels / mels.maxItem;

						melarray = mels.clump(melbuf.numChannels);

						mfccbuf.loadToFloatArray(action:{
							arg mfccs_;
							mfccarray = mfccs_.clump(mfccbuf.numChannels);
						});
					});
				});
			});
		});
	};

	sfv = SoundFileView(win,Rect(0,ploth + 40,plotw * 2,ploth))
	.background_(Color.white)
	.drawsBoundingLines_(false)
	.drawsRMS_(false)
	.gridOn_(false)
	.action_{
		arg view;
		var pos = view.selection(0)[0] + view.selection(0)[1];
		var norm = pos / view.soundfile.numFrames;
		var mels_ = melarray[(norm * melarray.size).asInteger];
		var mfccs_ = mfccarray[(norm * mfccarray.size).asInteger];

		view.setSelection(0,[pos,0]);

		"\nmels  from buf:  %".format(mels_).postln;
		"mfccs from buf:  %".format(mfccs_).postln;
		"mfccs from mels: %".format(dct.(mels_,nMFCCs)).postln;

		mels_msv.value_(mels_);
		mfccs = mfccs_;
		mfccs_msv.value_(mfccs_.linlin(-40,40,0,1));
		win.refresh;
	};

	cos_freq_sl.valueAction_(1);
	sfvpum.valueAction_(4);

	win.front;
};
)