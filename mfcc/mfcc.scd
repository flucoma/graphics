(
s.waitForBoot{
	var nMels = 40, win, mels_msv, mfccs_msv, nMFCCs = 13, plotw = 800, ploth = 400, uv, margin = 4, maxMel = 1;
	var mfcc_disp_range = 100;
	var epsilon = 1e-6;
	var mfccs = Array.fill(nMFCCs,{0});
	var mels = Array.fill(nMels,{0});
	var mel_disp_max = 1;
	var cos_freq_sl, invbut;
	var dispx, button_w = 40;
	var n_cos_freq_buts = 13;
	var sfv, pumitems;
	var melbuf = Buffer(s);
	var melarray, sfvpum;
	var mfccbuf = Buffer(s), mfccarray;
	var show_cosines = false;

	var get_mels_shape = {
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
		arg values, n_coeffs;
		var out;
		out = n_coeffs.collect{
			arg k;
			var scale;
			var v = values.collect{
				arg xn, n;
				var x = (((2 * n) + 1) * pi * k) / (2 * values.size);
				var c = cos(x) * xn;
				c;
			}.sum;
			if(k==0) {scale = (1/(4 * values.size)).sqrt} {scale = (1/(2 * values.size)).sqrt};
			v * 2 * scale
		};
		out;
	};

	var idct = {
		arg values, n_coeffs;
		var out;
		out = n_coeffs.collect{
			arg k;
			var scale = (2/values.size).sqrt;
			var v = values[1..].collect{
				arg xn, i;
				var n = i + 1;
				var x = (((2 * k) + 1) * pi * n) / (2 * values.size);
				var c = cos(x) * xn;
				c
			}.sum;
			var off = values[0] / values.size.sqrt;
			off + (v * scale)
		};
	};

	var set_mels = {
		arg update_msv = false, log = true;
		"\tnew mels:    %\t%".format(mels.size,mels).postln;
		"\told mfccs:   %\t%".format(mfccs.size,mfccs).postln;
		mfccs = dct.([mels,mels.max(epsilon).ampdb][log.asInteger],nMFCCs);
		"\tnew mfccs:   %\t%".format(mfccs.size,mfccs).postln;

		mfccs_msv.value_(mfccs.linlin(-1 * mfcc_disp_range,mfcc_disp_range,0,1,nil));

		if(update_msv,{
			mels_msv.value_(mels.linlin(0,maxMel,0,mel_disp_max,nil));
		});

		uv.refresh;
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
		mels = get_mels_shape.(sl.value,invbut.value.asBoolean) * maxMel;
		set_mels.(true,false);
	});

	dispx = dispx + 400;

	invbut = Button(win,Rect(dispx,0,100,20))
	.states_([["Not Inverted"],["Inverted"]])
	.action_{
		arg but;
		mels_msv.valueAction_(get_mels_shape.(cos_freq_sl.value,but.value.asBoolean) * maxMel);
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

		"Mels MultiSliderView action:".postln;
		"\tmsv values:  %\t%".format(msv.value.size,msv.value).postln;
		"\told mels:    %\t%".format(mels.size,mels).postln;
		mels[msv.index] = msv.value[msv.index].linlin(0,mel_disp_max,0,maxMel,nil);
		set_mels.(false);
	};

	mfccs_msv = MultiSliderView(win,Rect(plotw,20,plotw,ploth))
	.size_(nMFCCs)
	.drawRects_(true)
	.isFilled_(true)
	.drawLines_(false)
	.elasticMode_(true)
	.reference_(0.5.dup(nMFCCs))
	.action_{
		arg msv;

		"MFCC MultiSliderView action:".postln;
		"\tmsv values:    %\t%".format(msv.value.size,msv.value).postln;
		"\told mfccs:     %\t%".format(mfccs.size,mfccs).postln;
		mfccs[msv.index] = msv.value[msv.index].linlin(0.0,1.0,-40.0,40.0,nil);
		"\tnew mfccs:     %\t%".format(mfccs.size,mfccs).postln;
		"\told mels:      %\t%".format(mels.size,mels).postln;
		mels = idct.(mfccs ++ 0.dup(nMels-nMFCCs),nMels).dbamp;
		"\tnew mels:      %\t%".format(mels.size,mels).postln;
		"\tmels / maxMel: %\t%".format((mels / maxMel).size,mels / maxMel).postln;
		mels_msv.value_(mels / maxMel);

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
				get_mels_shape.(j,false).do{
					arg y, i;
					var xpos = (melw/2) + (i*melw);
					var ypos;
					var scaler = 2;
					// if(i==0){scaler = 2.15}{scaler=4.5};
					ypos = (ploth/2) + (y * amp * scaler * -1); // -1 is to flip the y axis as the display is from the top left
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
			FluidBufMelBands.processBlocking(s,buf,features:melbuf,normalize:0,action:{
				FluidBufMFCC.processBlocking(s,buf,features:mfccbuf,numCoeffs:40,numCoeffs:40,action:{
					melbuf.loadToFloatArray(action:{
						arg mels_;

						maxMel = mels_.maxItem;

						melarray = mels_.clump(melbuf.numChannels);

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
		var index = (norm * melarray.size).asInteger;

		mels = melarray[index];
		mfccs = mfccarray[index][..12];

		view.setSelection(0,[pos,0]);

		"\nSoundFileView action:".postln;
		"\tmfcc array size: %".format(mfccarray.size).postln;
		"\tmels array size: %".format(melarray.size).postln;
		"\tmels  from buf:  %".format(mels).postln;
		"\tmfccs from buf:  %".format(mfccs).postln;
		"\tmfccs from mels: %".format(dct.(mels.ampdb,nMFCCs)).postln;

		mels_msv.value_(mels / maxMel);
		mfccs_msv.value_(mfccs[..12].linlin(-1 * mfcc_disp_range,mfcc_disp_range,0.0,1.0,nil));
		win.refresh;
	};

	cos_freq_sl.valueAction_(1);
	sfvpum.valueAction_(4);

	win.front;
};
)