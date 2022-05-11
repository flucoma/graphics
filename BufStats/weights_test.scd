(
a = [1,2,3,4,5,6,7,8,9];
a.mean.postln;
[1,2,3,4,5,6,7,8].mean.postln;
d = Buffer.loadCollection(s,a);
b = Buffer(s);
w = Buffer.loadCollection(s,[1,1,1,1,1,1,1,1,-1]);
)
(
fork{
	FluidBufStats.processBlocking(s,d,stats:b,low:25,high:75);
	b.loadToFloatArray(action:{
		arg stats;
		stats.postln;
	});
	s.sync;
	FluidBufStats.processBlocking(s,d,stats:b,low:25,high:75,weights:w);
	b.loadToFloatArray(action:{
		arg stats;
		stats.postln;
	});
}
)

