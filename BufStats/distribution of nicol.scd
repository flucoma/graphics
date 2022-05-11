(
~drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
~mfcc = Buffer(s);
FluidBufMFCC.processBlocking(s,~drums,features:~mfcc);
~stats = Buffer(s);
FluidBufStats.processBlocking(s,~mfcc,stats:~stats);
~substats = Dictionary.new;
(FluidBufStats.stats ++ /*Array.fill(10,{
	rrand(2,6).collect{
		FluidBufStats.stats.choose;
	};
})*/ [[\high,\mid,\std],[ \high, \high, \mlid, \std ] ]).do{
	arg stat, i;
	var buf = Buffer(s);
	"stat %: %".format(i,stat).postln;
	~substats.put(stat,buf);
	if(stat.isSequenceableCollection.not){stat = [stat]};
	FluidBufStats.processBlocking(s,~mfcc,stats:buf,select:stat);
};
~stats.loadToFloatArray(action:{
	arg stats;
	fork{
		var cond = Condition.new;
		~substats.keysValuesDo{
			arg statname, substatbuf, i;
			substatbuf.loadToFloatArray(action:{
				arg substats;
				statname.postln;
				"from substats:".postln;
				substats.clump(13).dopostln;
				"".postln;
				cond.unhang;
			});
		};
		cond.hang;
	};
});
)

~ds = FluidDataSet(s).fromBuffer(~mfcc);

(
~distribution = {
	arg dataset, steps = 100, bounds;
	bounds = bounds ? Rect(0,0,800,820);
	dataset.dump({
		arg dict;
		var data = dict["data"].values.flop;
		var histograms = data.collect{arg dim; dim.histo(steps)};
		fork({
			var win = Window("Distributions",bounds);
			var plotter = Plotter("Distributions",Rect(0,20,win.bounds.width,win.bounds.height-20),win);
			plotter.plotMode_(\bars);
			EZSlider(win,Rect(0,0,win.bounds.width,20),"Dimension:",ControlSpec(0,histograms.size-1,step:1),{
				arg sl;
				plotter.value_(histograms[sl.value.asInteger]);
			},0,true,80);
			win.front;
		},AppClock);
	});
};
~distribution.(~ds,12,400,400);
)