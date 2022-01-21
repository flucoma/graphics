// define some functions
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

~matrix_maxItem = {
	arg mat;
	mat.collect{
		arg row;
		row.maxItem;
	}.maxItem;
};

~colors = CSVFileReader.readInterpret(FluidFilesPath("../Resources/color-schemes/CET-L16.csv")).collect{
	arg arr;
	Color.fromArray(arr);
};

~colors_blue_yellow = CSVFileReader.readInterpret(FluidFilesPath("../Resources/color-schemes/CET-L08.csv")).collect{
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

	var max = ~matrix_maxItem.(hv).max(epsilon);
	// ArrayXd mult = (1.0 / HV.max(epsilon));
	var mult = ~matrix_uniOp.(hv,{arg v; 1.0 / max});

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