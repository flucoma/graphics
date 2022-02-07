(
s.waitForBoot{

	var dct = {
		arg values, n_coeffs;
		var out;
		var nMels = values.size;
		out = n_coeffs.collect{
			arg k;
			var scale = (1/(2 *nMels)).sqrt;
			var v = values.collect{
				arg xn, n;
				var x = (((2 * n) + 1) * pi * k) / (2 * nMels);
				var c = cos(x) * xn;
				c;
			}.sum;
			if(k==0) {scale = (1/(4 * nMels)).sqrt};
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

	FluidBufMelBands.processBlocking(s,audio,features:melbuf);
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

			"mfccs / mfccs_hat:     %".format(mfccs / mfccs_hat).postln;
		});
	});
}
)