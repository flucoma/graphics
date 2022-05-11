(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
s.waitForBoot{
	var tableSize = 256;
	var sq = Buffer.alloc(s,tableSize);
	var compare_buf = Buffer(s);
	var tempbuf = Buffer.alloc(s,tableSize);
	var dispbuf = Buffer(s);
	var comparebuf = Buffer(s);
	var amps = List.new;
	var fundamental = s.sampleRate / tableSize;
	var partial = 1;

	while({
		(fundamental*partial) < (s.sampleRate/2)
	},{
		var amp;
		if((partial%2) == 1){amp = 1/partial}{amp = 0};
		amps.add(amp);
		partial = partial + 1;
	});

	s.sync;

	sq.sine1(amps,true,false,true);

	s.sync;

	sq.loadToFloatArray(action:{
		arg real;
		var	imag = Signal.newClear(tableSize);
		// var cosTable = Signal.fftCosTable(tableSize);
		var cosTable = nil;
		var complex = fft(real, imag, cosTable).postln;
		var polar = Polar(complex.magnitude,complex.phase.collect{
			arg ph;
			if(1.coin){rrand(-pi,pi)}{ph};
		});
		var ifft = polar.real.ifft(polar.imag, cosTable);
		var complex2 = fft(ifft, Signal.newClear(tableSize), cosTable);

		// [real, complex.magnitude, ifft.real, complex2.magnitude].flop.flat.plot("fft and back", Rect(0, 0, 512 + 8, 500), numChannels: 4);

		fork({
			var curr = 0;
			var mags = Buffer(s);
			var img;
			var fw;

			[
				real,
				complex.magnitude[..(tableSize/2).asInteger].resamp1(tableSize),
				ifft.real,
				complex2.magnitude[..(tableSize/2).asInteger].resamp1(tableSize)
			].do{
				arg arr, i;
				tempbuf.loadCollection(arr);
				s.sync;
				FluidBufCompose.processBlocking(s,tempbuf,destination:dispbuf,destStartChan:i);
				s.sync;
				if((i%2)==0){
					var n = ((s.sampleRate * 4) / tableSize).asInteger;
					tempbuf.loadCollection(arr);
					s.sync;
					n.do{
						FluidBufCompose.processBlocking(s,tempbuf,destination:comparebuf,destStartFrame:curr,gain:-20.dbamp);
						curr = curr + tableSize
					};
					s.sync;
					curr = curr + ((s.sampleRate / tableSize).asInteger * tableSize);
				}
			};

			s.sync;
			FluidBufSTFT.processBlocking(s,comparebuf,magnitude:mags);
			s.sync;

			outfolder.mkdir;

			fw = FluidWaveform(featuresBuffer:dispbuf,stackFeatures:true,bounds:Rect(0,0,1600,400));
			1.wait;
			img = Image.fromWindow(fw.parent);
			1.wait;
			img.write(outfolder+/+"waves.png","png",100);
			1.wait;
			fw.close;
			1.wait;

			fw = FluidWaveform(imageBuffer:mags,imageColorScheme:1,imageColorScaling:1);
			1.wait;
			img = Image.fromWindow(fw.parent);
			1.wait;
			img.write(outfolder+/+"spectrogram.png","png",100);
			1.wait;
			fw.close;
			1.wait;

			// comparebuf.play(mul:-26.dbamp);
			comparebuf.write(outfolder+/+"sounds.wav","wav");
		},AppClock);

	});
}
)