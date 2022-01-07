// define some functions
(
~matrix_to_spectrogram = {
	arg matrix, colors;
	var img = Image(matrix[0].size,matrix.size);
	//var maxItem = matrix.collect(_.maxItem).maxItem;
	var maxItem = 100;

	matrix = matrix.collect{
		arg row;
		(row / maxItem).ampdb.linlin(-120.0,0.0,0,255).asInteger;
	};

	matrix.do{
		arg row, y;
		row.do{
			arg mag, x;
			img.setColor(colors[mag],x,(matrix.size-1) - y);
		}
	};

	img;
};

~colors = CSVFileReader.readInterpret(FluidFilesPath("/color-schemes/CET-L16.csv")).collect{
	arg arr;
	Color.fromArray(arr);
};

~matrix_to_mask = {
	arg matrix, colors;
	var img = Image(matrix[0].size,matrix.size);

	matrix = matrix.collect{
		arg row;
		row * 255;
	};

	matrix.do{
		arg row, y;
		row.do{
			arg mag, x;
			img.setColor(colors[mag],x,(matrix.size-1) - y);
		}
	};

	img;
};

// implemented per: https://www.audiolabs-erlangen.de/content/resources/MIR/00-2019_CourseMIR_HfM-Karlsruhe/harmonic_percussive_source_separation.html
~median_filter = {
	arg array, filterSize = 5;
	var padded_array = 0.dup((filterSize-1) / 2) ++ array ++ 0.dup((filterSize-1) / 2);
	array = array.size.collect{
		arg i;
		// padded_array[i..(i + (filterSize-1))].sort.postln;
		// padded_array[i..(i + (filterSize-1))].median.postln;
		// "".postln;
		padded_array[i..(i + (filterSize-1))].median;
	};
	array;
};

~make_harmonic_enhanced_spectrum = {
	arg matrix, filterSize = 17;
	matrix.collect{
		arg row;
		~median_filter.(row,filterSize);
	};
};

~make_percussive_enhanced_spectrum = {
	arg matrix, filterSize = 31;
	matrix.flop.collect{
		arg frame;
		~median_filter.(frame,filterSize);
	}.flop;
};

~matrix_uniOp = {
	arg mat, func;
	mat.collect{
		arg row;
		row.collect{
			arg val;
			func.(val);
		};
	};
};

~matrix_binOp = {
	arg mat0, mat1, func;
	mat0.collect{
		arg row, i;
		row.collect{
			arg val, j;
			func.(val,mat1[i][j]);
		};
	};
};

// kClassic
~make_masks_soft = {
	arg harm, perc;
	var epsilon = 0.00001;

	// ArrayXd HV = mH.col(0) + mV.col(0);
	var hv = ~matrix_binOp.(harm,perc,{arg a, b; a + b});

	// ArrayXd mult = (1.0 / HV.max(epsilon));
	var mult = ~matrix_uniOp.(hv,{arg v; 1.0 / v.max(epsilon)});

	// harmonicMask = (mH.col(0) * mult);
	var harm_mask = ~matrix_binOp.(harm,mult,{arg a, b; a * b});

	// percussiveMask = (mV.col(0) * mult);
	var perc_mask = ~matrix_binOp.(perc,mult,{arg a, b; a * b});

	[harm_mask, perc_mask];
};

// kCoupled
~make_masks_binary = {
	arg harm, perc;

	var harm_mask = ~matrix_binOp.(harm,perc,{arg a, b; ((a / b) > 1).asInteger });
	var perc_mask = ~matrix_uniOp.(harm_mask,{arg val; 1 - val});

	[harm_mask, perc_mask];
};
)

// load a file to HPSS
~snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
~snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),startFrame:44100 * 1.157,numFrames:44100 * 0.291);

// check it if you want
// FluidWaveform(~snare,showSpectrogram:true,spectrogramColorScheme:1,showWaveform:false,bounds:Rect(0,0,1600,400));

// get magnitudes
~magbuf = Buffer(s);
FluidBufSTFT.process(s,~snare,magnitude:~magbuf,action:{"done".postln});

(
Window.closeAll;
~magbuf.loadToFloatArray(action:{
	arg mags;
	var stamp = Date.localtime.stamp;
	var folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"outputs/%".format(stamp);
	folder.mkdir;

	mags = mags.clump(~magbuf.numChannels).flop;

	defer{
		~matrix_to_spectrogram.(mags,~colors).write(folder+/+"%_00_Original_Spectrogram.png".format(stamp));

		~harm_enhanced = ~make_harmonic_enhanced_spectrum.(mags,17);
		~matrix_to_spectrogram.(~harm_enhanced,~colors).write(folder+/+"%_01_Harmonic_Enhanced_Spectrogram.png".format(stamp));

		~perc_enhanced = ~make_percussive_enhanced_spectrum.(mags,31);
		~matrix_to_spectrogram.(~perc_enhanced,~colors).write(folder+/+"%_02_Percussive_Enhanced_Spectrogram.png".format(stamp));

		~soft_masks = ~make_masks_soft.(~harm_enhanced,~perc_enhanced);
		~matrix_to_mask.(~soft_masks[0],~colors).write(folder+/+"%_03_Harmonic_Mask_(Soft).png".format(stamp));
		~matrix_to_mask.(~soft_masks[1],~colors).write(folder+/+"%_04_Percussive_Mask_(Soft).png".format(stamp));
		~harm_ouptut_soft = ~matrix_binOp.(mags,~soft_masks[0],{arg a, b; a * b.min(1)});
		~perc_ouptut_soft = ~matrix_binOp.(mags,~soft_masks[1],{arg a, b; a * b.min(1)});
		~matrix_to_spectrogram.(~harm_ouptut_soft,~colors).write(folder+/+"%_05_Harmonic_Output_(Soft_Mask).png".format(stamp));
		~matrix_to_spectrogram.(~perc_ouptut_soft,~colors).write(folder+/+"%_06_Percussive_Output_(Soft_Mask).png".format(stamp));

		~binary_masks = ~make_masks_binary.(~harm_enhanced,~perc_enhanced);
		~matrix_to_mask.(~binary_masks[0],~colors).write(folder+/+"%_07_Harmonic_Mask_(Binary).png".format(stamp));
		~matrix_to_mask.(~binary_masks[1],~colors).write(folder+/+"%_08_Percussive_Mask_(Binary).png".format(stamp));
		~harm_ouptut_binary = ~matrix_binOp.(mags,~binary_masks[0],{arg a, b; a * b.min(1)});
		~perc_ouptut_binary = ~matrix_binOp.(mags,~binary_masks[1],{arg a, b; a * b.min(1)});
		~matrix_to_spectrogram.(~harm_ouptut_binary,~colors).write(folder+/+"%_09_Harmonic_Output_(Binary_Mask).png".format(stamp));
		~matrix_to_spectrogram.(~perc_ouptut_binary,~colors).write(folder+/+"%_10_Percussive_Output_(Binary_Mask).png".format(stamp));

		"all done".postln;
	}
});
)