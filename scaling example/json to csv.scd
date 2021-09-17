(
s.waitForBoot{
	Routine{
		var ds = FluidDataSet(s);

		s.sync;

		ds.read("/Users/macprocomputer/Desktop/_flucoma/learn/scaling/jsons/210910_153717/drums_raw_210910_153717.json",{
			ds.dump({
				arg dict;
				var data_size = dict.at("data").size;
				var data = Array.newClear(data_size);
				var ids = Array.newClear(data_size);
				// var stamp = Date.localtime.stamp;
				var destination_path = "/Users/macprocomputer/Desktop/_flucoma/code/graphics/scaling example";

				dict.at("data").keysValuesDo({
					arg id, vec, i;
					data[i] = vec;
					ids[i] = id;
				});

				ArrayToCSV(ids, "%/drums_raw_ids.csv".format(destination_path));
				ArrayToCSV(data,"%/drums_raw_data.csv".format(destination_path));


			});
		});
	}.play;
};
)

