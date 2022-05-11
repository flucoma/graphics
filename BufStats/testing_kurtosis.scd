(
a = Array.fill(1000000,{
	[
		gauss(0,1),
		[gauss(0,1),gauss(0,0.5)].wchoose([1,2].normalizeSum),
		// rrand(-1.0,1.0)
		[gauss(0,1),gauss(0,1.5)].wchoose([1,2].normalizeSum),

	];
});
~histos = a.flop.collect{arg arr; arr.histo(1000,-6,6)};
b = Buffer.loadCollection(s,a.flat,3);
c = Buffer(s);
~histobuf = Buffer.loadCollection(s,~histos.flop.flat,3);
)

FluidWaveform(featuresBuffer:~histobuf,bounds:Rect(0,0,1600,400),normalizeFeaturesIndependently:false);


/////////////////////////////////////////////////////////////
FluidBufStats.processBlocking(s,b,stats:c,action:{"done".postln;});

(
c.loadToFloatArray(action:{
	arg fa;
	fa.clump(3).flop.dopostln;
});
)

(
b = Buffer.loadCollection(s,Array.fill(999999,{rrand(-0.5,0.5)}));
c = Buffer(s);
)

FluidBufStats.processBlocking(s,b,stats:c);

(
c.loadToFloatArray(action:{
	arg fa;
	fa.postln;
});
)

