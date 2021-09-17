(
s.waitForBoot{
	Routine{
		var ds = FluidDataSet(s);
		var robust_scaler = FluidRobustScale(s);
		var x_buf = Buffer.alloc(s,2);
		var y_buf = Buffer.alloc(s,2);

		s.sync;

		ds.read("/Users/macprocomputer/Desktop/_flucoma/learn/scaling/jsons/210910_153717/drums_raw_210910_153717.json",{
			robust_scaler.fit(ds,{
				robust_scaler.dump({
					arg dict;
					dict.postln;
					x_buf.loadCollection(dict.at("data_low"),action:{
						robust_scaler.transformPoint(x_buf,y_buf,{
							y_buf.loadToFloatArray(action:{
								arg y_fa0;
								"data low: ".post;
								y_fa0.postln;

								x_buf.loadCollection(dict.at("data_high"),action:{
									robust_scaler.transformPoint(x_buf,y_buf,{
										y_buf.loadToFloatArray(action:{
											arg y_fa1;
											"data high: ".post;
											y_fa1.postln;
										});
									});
								});
							});
						});
					});
				});
			});
		});
	}.play;
};
)
