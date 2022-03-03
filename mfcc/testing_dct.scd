(
s.waitForBoot{

	var dct = {
		arg values,nMFCCs;
		var out;
		var nMels = values.size;
		out = nMFCCs.collect{
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

	var idct = {
		// TODO:
		"Not yet implemented".warn;
	};

	var audio = Buffer.read(s,FluidFilesPath("Harker-DS-TenOboeMultiphonics-M.wav"));
	var melbuf = Buffer(s);
	var mfccbuf = Buffer(s);

	FluidBufMelBands.processBlocking(s,audio,features:melbuf,normalize:0);
	FluidBufMFCC.processBlocking(s,audio,features:mfccbuf,numCoeffs:40);

	s.sync;

	// make sure they have the same number of frames
	melbuf.postln;
	mfccbuf.postln;

	melbuf.loadToFloatArray(action:{
		arg melarray;

		melarray = melarray.clump(melbuf.numChannels);

		mfccbuf.loadToFloatArray(action:{
			arg mfccarray;
			var index, mels, mfccs, mfccs_hat;

			mfccarray = mfccarray.clump(mfccbuf.numChannels);

			// choose some point in time:
			index = 1000;

			mels = melarray[index];
			mfccs = mfccarray[index];
			mfccs_hat = dct.(mels.ampdb,13);

			"".postln;
			"mels:                  %".format(mels).postln;
			"mfccs:                 %".format(mfccs).postln;
			"mfccs_hat (using dct): %".format(mfccs_hat).postln;

			// "mfccs / mfccs_hat:     %".format(mfccs / mfccs_hat).postln;
		});
	});
}
)

(
var dct = {
	arg values,nMFCCs;
	var out;
	var nMels = values.size;
	out = nMFCCs.collect{
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
var idct = {
	arg values, n_coeffs;
	var out;
	var nMFCCs = values.size;
	out = n_coeffs.collect{
		arg k;
		var scale = (2/nMFCCs).sqrt;
		var v = values[1..].collect{
			arg xn, i;
			var n = i + 1;
			var x = (((2 * k) + 1) * pi * n) / (2 * nMFCCs);
			var c = cos(x) * xn;
			c
		}.sum;
		var off = values[0] / nMFCCs.sqrt;
		off + (v * scale)
	};
};

v = {rrand(0,100.0)} ! 40;
// "dct:  %".format(dct.(v)).postln;
"".postln;
"v:    %".format(v).postln;
~dct = dct.(v,13);
"dct out size: %".format(~dct.size).postln;
~idct = idct.(~dct,~dct.size);
);
"idct: %".format(~idct).postln;
/*"".postln;
"i/d:  %".format(~idct/~dct).postln;
"i-d:  %".format(~idct-~dct).postln;*/
"";
)