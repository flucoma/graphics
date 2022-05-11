~snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),202301,4000);

(
~out_folder = thisProcess.nowExecutingPath.dirname+/+"outputs/%_outliersCutoff".format(Date.localtime.stamp);
fork{
	~percentile = {
		arg data, pctile;
		var sorted = data.copy.sort;
		var idx = ((pctile/100) * (sorted.size-1)).round;
		sorted[idx];
	};


	a = [15, 20, 35, 40, 50];
	/*	"wikipedia says 15 : ted says ".post; ~percentile.(a,0).postln;
	"wikipedia says 15 : ted says ".post; ~percentile.(a,5).postln;
	"wikipedia says 20 : ted says ".post; ~percentile.(a,30).postln;
	"wikipedia says 20 : ted says ".post; ~percentile.(a,40).postln;
	"wikipedia says 35 : ted says ".post; ~percentile.(a,50).postln;
	"wikipedia says 50 : ted says ".post; ~percentile.(a,100).postln;*/

	b = Buffer.loadCollection(s,a);
	s.sync;
	c = Buffer(s);
	FluidBufStats.processBlocking(s,b,stats:c,middle:5,high:30);
	c.loadToFloatArray(action:{
		arg fa;
		"".postln;
		// "wikipedia says [ 15, 15, 20 ]".postln;
		"flucoma says   %".format(fa[4..6].asInteger.asArray).postln;
		"ted says       [ %, %, % ]".format(~percentile.(a,0),~percentile.(a,5),~percentile.(a,30)).postln;
	});

	s.sync;
	FluidBufStats.processBlocking(s,b,stats:c,low:40,middle:50);
	c.loadToFloatArray(action:{
		arg fa;
		"".postln;
		// "wikipedia says [ 20, 35, 50 ]".postln;
		"flucoma says   %".format(fa[4..6].asInteger.asArray).postln;
		"ted says       [ %, %, % ]".format(~percentile.(a,40),~percentile.(a,50),~percentile.(a,100)).postln;

	});

	s.sync;
	"".postln;

	/*	"wikipedia says 3  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 10, 13, 15, 16, 20],0).postln;
	"wikipedia says 7  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 10, 13, 15, 16, 20],25).postln;
	"wikipedia says 8  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 10, 13, 15, 16, 20],50).postln;
	"wikipedia says 15 : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 10, 13, 15, 16, 20],75).postln;
	"wikipedia says 20 : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 10, 13, 15, 16, 20],100).postln;

	"".postln;

	"wikipedia says 3  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20],0).postln;
	"wikipedia says 7  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20],25).postln;
	"wikipedia says 9  : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20],50).postln;
	"wikipedia says 15 : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20],75).postln;
	"wikipedia says 20 : ted says ".post; ~percentile.([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20],100).postln;*/

	~low = 0;
	~middle = 50;
	~high = 100;
	~outliersCutoff = 1.1;
	~json = Dictionary.new;

	~specShape = Buffer(s);
	FluidBufSpectralShape.processBlocking(s,~snare,features:~specShape);
	~specShape.loadToFloatArray(action:{
		arg fa;
		~specShapeArr = fa.clump(7).flop;
		"\nspectral shape buffer:".postln;
		~specShapeArr.dopostln;
		~out_folder.mkdir;

		~json.put("FluidSpectralShape",~specShapeArr.copy);
		~json.put("percentiles_range_bounds",List.new);

		ArrayToCSV(~specShapeArr,~out_folder+/+"00_FluidSpectralShape_output.csv");
		~iqrbounds = ~specShapeArr.collect{
			arg chan;
			var q1 = ~percentile.(chan,25);
			var q3 = ~percentile.(chan,75);
			var margin = (q3 - q1) * ~outliersCutoff;
			~json["percentiles_range_bounds"].add([q1,q3,q3-q1,margin,q1-margin,q3+margin]);
			[q1,q3,q3-q1,margin,q1-margin,q3+margin];
		};

		~json.put("outliersCutoff",~outliersCutoff);
		~json.put("iqrBounds",~iqrbounds.copy);

		ArrayToCSV(~iqrbounds.collect{
			arg chan, i;
			["channel_%".format(i)] ++ chan;
		},~out_folder+/+"01_bounds.csv");
	});
	~stats = Buffer(s);
	FluidBufStats.processBlocking(s,~specShape,stats:~stats);
	~stats.loadToFloatArray(action:{
		arg fa;
		"\nstats bufffer:".postln;
		~statsArr = fa.clump(7).flop;

		~json.put("FluidBufStats_outliersCutoff=-1",~statsArr.copy);

		ArrayToCSV(~statsArr,~out_folder+/+"02_FluidBufStats_outliersCutoff=-1.csv");
		~statsArr.dopostln;
	});

	s.sync;

	~specShapeArr = ~specShapeArr.collect{
		arg chan, i;
		chan = chan.collect{
			arg val;
			var upperbound = ~iqrbounds[i][1];
			var lowerbound = ~iqrbounds[i][0];
			if((val > upperbound) || (val < lowerbound),{
				val = nil;
			});
			val;
		};
	};

	"\nspecShapeArr with nils:".postln;
	~specShapeArr.dopostln;

	ArrayToCSV(~specShapeArr,~out_folder+/+"03_specShapeArr_with_nils.csv");

	~json.put("SpecShapeArr_with_nils",~specShapeArr.copy);

	~specShapeArr = ~specShapeArr.flop.select{
		arg frame;
		frame.includes(nil).not;
	}.flop;

	"\nspecShapeArr filtered:".postln;
	~specShapeArr.dopostln;

	ArrayToCSV(~specShapeArr,~out_folder+/+"04_specShapeArr_filtered.csv");

	~json.put("SpecShapeArr_filtered",~specShapeArr.copy;);

	"\nmanual stats on specShapeArr filtered".postln;
	~specShapeArr.collect{
		arg chan;
		var vec = [chan.mean, "stddev","skew","kurt",~percentile.(chan,~low),~percentile.(chan,~middle),~percentile.(chan,~high)];
		vec.postln;
		vec;
	};//,~out_folder+/+"04_manual_stats_on_specShapeArr_filtered_outliersCutoff=%.csv".format(~outliersCutoff));

	"\nstats with outliersCutoff=%".format(~outliersCutoff).postln;
	~statsCutoff = Buffer(s);
	FluidBufStats.processBlocking(s,~specShape,stats:~statsCutoff,outliersCutoff:~outliersCutoff,low:~low,middle:~middle,high:~high);
	~statsCutoff.loadToFloatArray(action:{
		arg fa;
		fa = fa.clump(7).flop;
		fa.dopostln;
		~json.put("FluidBufStats_outliersCutoff!=-1",fa);
		ArrayToCSV(fa,~out_folder+/+"05_FluidBufStats_outliersCutoff=%.csv".format(~outliersCutoff));
		JSONWriter(~json,~out_folder+/+"bufstats.json");
	});
};
)