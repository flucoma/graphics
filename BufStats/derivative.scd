c = [10,15,30,20,25,12,0,24,40];
b = Buffer.loadCollection(s,c);
t = Buffer(s);

FluidBufStats.processBlocking(s,b,stats:t,numDerivs:1);

(
t.loadToFloatArray(action:{
	arg fa;
	fa.postln;
	fa[7].postln;
});
)

(
~derivative = {
	arg series;
	(series.size-1).collect{
		arg i;
		series[i+1] - series[i];
	};
};
~post = {
	arg series;
	"| ".post;
	series.do{
		arg val;
		val.post;
		" | ".post;
	};
	"".postln;
};
~post.(c);
c.mean.postln;
c.median.postln;
"".postln;
a = ~derivative.(c);
~post.(a);
a.mean.postln;
a.median.postln;
"".postln;
b = ~derivative.(a);
~post.(b);
b.mean.postln;
b.median.postln;
"".postln;
)

Buffer