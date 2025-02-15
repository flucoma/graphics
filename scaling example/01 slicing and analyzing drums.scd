(
~folder = thisProcess.nowExecutingPath.dirname+/+"%-drums".format(Date.localtime.stamp);
// slice
// s.options.outDevice_("MacBook Pro Speakers");
s.options.outDevice_("External Headphones");
s.options.inDevice_("MacBook Pro Microphone");
// s.options.sampleRate_(44100);
s.waitForBoot{
	//var path = "/Users/macprocomputer/Desktop/_flucoma/learn/scaling/test01.wav";
	var path = FluidFilesPath("Nicol-LoopE-M.wav");
	// var path = "/Users/macprocomputer/Desktop/_flucoma/code/flucoma-core-src/AudioFiles/Tremblay-ASWINE-ScratchySynth-M.wav";
	Routine{
		var process_slicePoints = {
			Routine{
				var start_num_dict = Dictionary.newFrom(["cols",2,"data",Dictionary.new]);
				var cond = Condition.new;

				var write = true;

				if(write,{
					var proj = ReaProj();
					var track = ReaTrack();
					var rea_offset = 0;
					~folder.mkdir;
					~slicePoints.do{
						arg arr, i;
						var start = arr[0];
						var end = arr[1];
						var num = end - start;
						var new_buf = Buffer.alloc(s,num);
						s.sync;
						FluidBufCompose.process(s,~drums,start,num,destination:new_buf,action:{
							var slice_path = ~folder+/+"slice-%.wav".format(i);
							track.addItem(ReaItem(slice_path,rea_offset,new_buf.duration.postln));

							rea_offset = rea_offset + 1;

							new_buf.write(slice_path,"wav",completionMessage:{
								new_buf.postln;
								[start,num].postln;
								cond.unhang;
							});
						});
						cond.hang;
					};
					proj.addTrack(track);
					proj.write(~folder+/+"slices.RPP");
				});


				~slicePoints.do{
					arg arr, i;
					var start = arr[0];
					var end = arr[1];
					var num = end - start;
					start_num_dict.at("data").put("slice-%".format(i),[start,num]);
				};

				~slicePoints_ds.load(start_num_dict,{~slicePoints_ds.dump});

				/*				~slicePoints.do{
				arg arr, i;
				var start_samps = arr[0];
				var end_samps = arr[1];
				var dur_samps = end_samps - start_samps;
				var dur_secs = dur_samps / ~drums.sampleRate;

				"playing slice % / %".format(i+1,~slicePoints.size-1).postln;
				//start_samps.postln;
				"".postln;

				{
				var sig = PlayBuf.ar(~drums.numChannels,~drums,BufRateScale.ir(~drums),startPos:start_samps);
				var env = EnvGen.kr(Env([0,1,1,0],[0.03,dur_secs-0.06,0.03]),doneAction:2);
				sig * env;
				}.play;

				(dur_secs + 1).wait;
				};*/
			}.play;
		};

		var slice_points_to_2d = {
			arg action;
			~slicePoints.loadToFloatArray(action:{
				arg sp_fa;
				var sp_new = List.new;
				(sp_fa.size-1).do({
					arg i;
					sp_new.add([sp_fa[i],sp_fa[i+1]]);
				});
				~slicePoints = sp_new;
				action.value;
			});
		};

		~drums = Buffer.read(s,path);
		~slicePoints = Buffer(s);
		~slicePoints_ds = FluidDataSet(s);

		s.sync;

		FluidBufOnsetSlice.process(s,~drums,indices:~slicePoints,threshold:0.05,action:{
			~slicePoints.loadToFloatArray(action:{
				arg fa;

				process_slicePoints.value;
			});
		});

	}.play;
}
)

(
var folder = thisProcess.nowExecutingPath.dirname;
// analyze
Routine{
	var spec_buf = Buffer(s);
	var spec_stats = Buffer(s);
	var loudness_buf = Buffer(s);
	var loudness_stats = Buffer(s);
	var x_buf = Buffer.alloc(s,2);
	var playback_points_buf = Buffer.alloc(s,2);
	var condition = Condition.new;
	var json = Dictionary.new;

	json["start-num"] = Dictionary.new;
	json["raw"] = Dictionary.new;
	json["norm"] = Dictionary.new;
	json["std"] = Dictionary.new;
	json["robust"] = Dictionary.new;

	~ds = FluidDataSet(s);
	~norm = FluidDataSet(s);
	~std = FluidDataSet(s);
	~robust = FluidDataSet(s);

	s.sync;

	~slicePoints.do{
		arg arr, i;
		var start_samps = arr[0];
		var end_samps = arr[1];
		var dur_samps = end_samps - start_samps;

		FluidBufSpectralShape.process(s,~drums,start_samps,dur_samps,features:spec_buf,action:{
			FluidBufStats.process(s,spec_buf,numChans:1,stats:spec_stats,action:{
				FluidBufLoudness.process(s,~drums,start_samps,dur_samps,features:loudness_buf,action:{
					FluidBufStats.process(s,loudness_buf,numChans:1,stats:loudness_stats,action:{
						FluidBufCompose.process(s,spec_stats,numFrames:1,destination:x_buf,action:{
							FluidBufCompose.process(s,loudness_stats,numFrames:1,destination:x_buf,destStartFrame:1,action:{
								var id = "slice-%".format(i);

								json["start-num"][id] = [start_samps,dur_samps];

								~ds.addPoint(id,x_buf,{
									condition.unhang;
								});
							});
						});
					});
				});
			});
		});
		"analyzing slice % / % complete".format(i+1,~slicePoints.size).postln;
		//start_samps.postln;
		//dur_samps.postln;
		//"".postln;
		condition.hang;
	};

	s.sync;

	FluidNormalize(s).fitTransform(~ds,~norm);
	FluidStandardize(s).fitTransform(~ds,~std);
	FluidRobustScale(s).fitTransform(~ds,~robust);

	[~ds,"raw",~norm,"norm",~std,"std",~robust,"robust"].clump(2).do{
		arg arr;
		var name = arr[1];
		var ds = arr[0];
		ds.dump({
			arg dict;
			dict["data"].keysValuesDo{
				arg k, v;
				json[name][k] = v;
			};
		});
	};

	s.sync;

}.play;
)

(
// compare
Routine{
	var scale_fit = {
		arg ev, action;
		ev.scaler.fitTransform(~ds,ev.ds,{
			// ~ds.print;
			// ev.ds.print;
			// "\n\n\n\n\n".postln;
			ev.display_scaler.fitTransform(ev.ds,ev.display_ds,{
				// ev.display_ds.print;
				ev.tree.fit(ev.ds,{
					action.value;
				});
			});
		});
	};

	~norm = ();
	~stand = ();
	~robust = ();
	~raw = ();
	~x_buf = Buffer.alloc(s,2);

	~get_nearest = {
		arg id, ev, action;
		ev.ds.getPoint(id,~x_buf,{
			ev.tree.kNearest(~x_buf,{
				arg nearest_list;
				action.(nearest_list[1]);
			});
		});
	};

	~raw.ds = ~ds;
	~raw.tree = FluidKDTree(s,2);
	~raw.name = "raw";

	~norm.scaler = FluidNormalize(s);
	~norm.display_scaler = FluidNormalize(s);
	~norm.ds = FluidDataSet(s);
	~norm.display_ds = FluidDataSet(s);
	~norm.tree = FluidKDTree(s,2);
	~norm.name = "norm";

	~stand.scaler = FluidStandardize(s);
	~stand.display_scaler = FluidNormalize(s);
	~stand.ds = FluidDataSet(s);
	~stand.display_ds = FluidDataSet(s);
	~stand.tree = FluidKDTree(s,2);
	~stand.name = "stand";

	~robust.scaler = FluidRobustScale(s);
	~robust.display_scaler = FluidNormalize(s);
	~robust.ds = FluidDataSet(s);
	~robust.display_ds = FluidDataSet(s);
	~robust.tree = FluidKDTree(s,2);
	~robust.name = "robust";

	s.sync;

	~raw.tree.fit(~raw.ds,{
		scale_fit.(~norm,{

			~raw.display_ds = ~norm.display_ds;

			scale_fit.(~stand,{
				scale_fit.(~robust,{
					~ds.dump({
						arg dict;
						Routine{
							var condition = Condition.new;
							//var nn_chart = Array.newClear(dict.at("data").size);
							var neighbor_bags = Dictionary.new;
							~nn_chart = Dictionary.new;
							dict.at("data").keysValuesDo({
								arg key, val, i_;
								~nn_chart.put(key,Array.newClear(4));

								neighbor_bags.put(key,Bag.new);

								~ds.getPoint(key,~x_buf,{
									~raw.tree.kNearest(~x_buf,{
										arg nearest_list;

										~nn_chart.at(key)[0] = nearest_list[1];
										neighbor_bags.at(key).add(nearest_list[1]);
										~get_nearest.(key,~norm,{
											arg near0;

											~nn_chart.at(key)[1] = near0;
											neighbor_bags.at(key).add(near0);
											~get_nearest.(key,~stand,{
												arg near1;

												~nn_chart.at(key)[2] = near1;
												neighbor_bags.at(key).add(near1);
												~get_nearest.(key,~robust,{
													arg near2;

													~nn_chart.at(key)[3] = near2;
													neighbor_bags.at(key).add(near2);
													if(neighbor_bags.at(key).contents.size > 2,{
														"point:\t\t\t\t\t\t%".format(key).postln;
														"contents:\t\t\t\t\t%".format(neighbor_bags.at(key).contents.size).postln;

														"raw data nearest neighbor:\t%".format(nearest_list[1]).postln;
														"% nearest neighbor:\t\t%".format(~norm.name,near0).postln;
														"% nearest neighbor:\t\t%".format(~stand.name,near1).postln;
														"% nearest neighbor:\t%".format(~robust.name,near2).postln;
														if(neighbor_bags.at(key).contents.size == 4,{
															"--- ALL NEIGHBORS ARE DIFFERENT FOR %".format(key).postln;
														});
														"".postln;
													});


													condition.unhang;
												});
											});
										});
									});
								});
								condition.hang;
							});

							//ArrayToCSV(nn_chart,"/Users/macprocomputer/Desktop/_flucoma/code/graphics/scaling example/neighbors_chart.csv");

							/*							~stamp = Date.localtime.stamp;
							~dir = "/Users/macprocomputer/Desktop/_flucoma/learn/scaling/jsons/%/".format(~stamp);
							~dir.mkdir;
							~raw.ds.write(~dir+/+"drums_raw_%.json".format(~stamp));
							~norm.ds.write(~dir+/+"drums_norm_%.json".format(~stamp));
							~stand.ds.write(~dir+/+"drums_stand_%.json".format(~stamp));
							~robust.ds.write(~dir+/+"drums_robust_%.json".format(~stamp));*/
						}.play;
					});
				});
			});
		});
	});
}.play;
)

(
// hear
Routine{
	// blues
	// var seq = ["slice-27","slice-21","slice-13","slice-23","slice-23"]; // kick
	// var seq = ["slice-18","slice-8","slice-6","slice-28","slice-28"]; // snare
	// var seq = ["slice-8","slice-18","slice-9","slice-13","slice-13"]; // hh

	// oranges
	// var seq = ["slice-16","slice-13","slice-22","slice-17"]; // the oranges
	// var seq = ["slice-17","slice-15","slice-28","slice-28","slice-21"]; // one of the oranges, raw is least good
	// var seq = ["slice-22","slice-20","slice-25","slice-25","slice-5"]; // one of the oranges, raw is best
	// var seq = ["slice-13","slice-10","slice-27","slice-27","slice-9"]; // norm / stand is best
	// var seq = ["slice-16","slice-11","slice-2","slice-2","slice-12"]; // not interesting

	// purple
	// var seq = ["slice-20","slice-22","slice-22","slice-22","slice-21"];


	var id = "slice-16";

	var seq = [id] ++ ~nn_chart.at(id);


	var buf = Buffer.alloc(s,2);
	var play_pt = {
		arg pt;
		~slicePoints_ds.getPoint(pt,buf,{
			buf.loadToFloatArray(action:{
				arg arr;
				var start = arr[0];
				var num = arr[1];
				var dur_sec = num / ~drums.sampleRate;
				{
					var sig = PlayBuf.ar(1,~drums,BufRateScale.ir(~drums),startPos:start,loop:0);
					var env = EnvGen.kr(Env([0,1,1,0],[0.03,0.06-dur_sec,0.03]),doneAction:2);
					sig.dup * env;
				}.play;
			});
		});
	};
	s.sync;

	seq.do{
		arg id;
		play_pt.(id);
		1.5.wait;
	};
}.play;
)

~ds.write("/Users/macprocomputer/Desktop/_flucoma/learn/scaling/drums_dataset_raw_%.json".format(Date.localtime.stamp));

(
// plot
Window.closeAll;
Routine{
	var normer = FluidNormalize(s);
	// var standardizer = FluidStandardize(s);
	var ds_normed = FluidDataSet(s);
	// var ds_stand = FluidDataSet(s);
	var tree_norm = FluidKDTree(s,2);
	var playback_points_buf = Buffer.alloc(s,2);
	var x_buf = Buffer.alloc(s,2);

	var lines_dict = Dictionary.new;
	var evs = Dictionary.new;

	var ds_to_data = {
		arg ev, action;
		// "ds to data ds: %".format(ev.display_ds).postln;
		// ev.display_ds.print;
		ev.ds.dump({
			arg dict0;

			ev.ids = Array.newClear(dict0.at("data").size);
			ev.data = Array.newClear(dict0.at("data").size);
			ev.id_to_idx = Dictionary.new;

			dict0.at("data").keysValuesDo{
				arg key, val, i;
				ev.data[i] = val;
				ev.ids[i] = key;
				ev.id_to_idx.put(key,i);
			};

			// ev.data.postln;
			action.value;
		});
	};

	// "ppb: %".format(playback_points_buf).postln;

	ds_to_data.(~raw,{
		ds_to_data.(~norm,{
			ds_to_data.(~stand,{
				ds_to_data.(~robust,{
					// var current_ev = ~raw;

					~norm.display_scaler.dump({
						arg norm_dict;
						~stand.display_scaler.dump({
							arg stand_dict;
							~robust.display_scaler.dump({
								arg robust_dict;
								var minx = min(stand_dict.at("data_min")[0],robust_dict.at("data_min")[0]);
								var miny = min(stand_dict.at("data_min")[1],robust_dict.at("data_min")[1]);
								var maxx = max(stand_dict.at("data_max")[0],robust_dict.at("data_max")[0]);
								var maxy = max(stand_dict.at("data_max")[1],robust_dict.at("data_max")[1]);

								evs.put("raw",~raw);
								evs.put("norm",~norm);
								evs.put("stand",~stand);
								evs.put("robust",~robust);

								lines_dict.put("raw",Dictionary.newFrom(["pts",[0,0],"color",Color.black]));
								lines_dict.put("norm",Dictionary.newFrom(["pts",[0,0],"color",Color.red]));
								lines_dict.put("stand",Dictionary.newFrom(["pts",[0,0],"color",Color.green]));
								lines_dict.put("robust",Dictionary.newFrom(["pts",[0,0],"color",Color.blue]));

								/*s.sync;*/

								~ds.dump({
									arg dict;
									Task{
										var pt_radius = 2;
										var pt_diam = pt_radius * 2;
										var plot_size = 1000;
										var scaler_pt = Point(plot_size,plot_size);
										var pt_radius_scaled = pt_radius.linlin(0,plot_size,0,1);
										//var data = Array.newClear(dict.at("data").size);
										//var ids = Array.newClear(dict.at("data").size);
										//var id_to_idx = Dictionary.new;
										var last_i = -1;
										var nearest_pair = Array.fill(2,{0});
										var win = Window(bounds:Rect(100,100,plot_size,plot_size + 20));
										var uv = UserView(win,Rect(0,20,plot_size,plot_size));
										var plotpum;

										plotpum = PopUpMenu(win,Rect(0,0,200,20))
										.items_(lines_dict.keys.asArray)
										.action_{
											arg pum;
											defer{uv.refresh};
										};

										plotpum.visible_(false);

										uv.drawFunc_{
											var listing_offset = 0;
											var data;
											// "pum item in drawfunc: %".format(plotpum.item).postln;
											data = evs.at(plotpum.item).data;

											// evs.at(plotpum.item).name.postln;
											// data[0].postln;

											lines_dict.keysValuesDo{
												arg key, val, i;
												var pts = val.at("pts");
												var pt1, pt2;
												var label_pt;
												// key.postln;
												pt1 = Point(data[pts[0]][0],data[pts[0]][1]) * plot_size;
												pt2 = Point(data[pts[1]][0],data[pts[1]][1]) * plot_size;

												// [pt1,pt2].postln;
												label_pt = pt2;

												if(i == 0,{
													Pen.stringAtPoint("source",pt1,color:Color.black);
												});

												Pen.line(pt1,pt2);
												Pen.color_(val.at("color"));
												Pen.stroke;

												pt2.y = pt2.y + listing_offset;
												Pen.stringAtPoint(key,pt2,color:Color.black);
												Pen.stroke;

												listing_offset = listing_offset + 10;
											};

											data.do{
												arg vals;
												var x_, y_;

												x_ = vals[0].linlin(0,1,0,plot_size - pt_diam);
												y_ = vals[1].linlin(0,1,0,plot_size - pt_diam);
												Pen.addOval(Rect(x_,y_,pt_diam,pt_diam));
												Pen.color_(Color.black);
												Pen.fill;
											};
										};

										uv.mouseOverAction_{
											arg view, x_, y_;
											var smallest_dist = inf;
											var winner = nil;
											var data = evs.at(plotpum.item).data;
											var ids = evs.at(plotpum.item).ids;
											var id_to_idx = evs.at(plotpum.item).id_to_idx;

											x_ = x_.linlin(0,plot_size - pt_diam,0,1);
											y_ = y_.linlin(0,plot_size - pt_diam,0,1);

											data.do{
												arg pt, i;
												var dist = ([x_,y_] - pt_radius_scaled.dup - pt).pow(2).sum.sqrt;
												if((dist < pt_radius_scaled) && (last_i != i),{
													var id = ids[i];
													var self_i = id_to_idx.at(id);

													last_i = i;
													~ds_playback.getPoint(id,playback_points_buf,{
														playback_points_buf.loadToFloatArray(action:{
															arg fa;
															var start_samps = fa[0];
															var num_samps = fa[1];
															{
																var sig = PlayBuf.ar(~drums.numChannels,~drums,BufRateScale.ir(~drums),startPos:start_samps);
																var env = EnvGen.kr(Env([0,1,1,0],[0.03,(num_samps / ~drums.sampleRate) - 0.06, 0.03]),doneAction:2);
																sig * env;
															}.play;
														});
													});

													"\n\nSOURCE POINT:\t\t\t\t\t\t%".format(id).postln;

													~get_nearest.(id,~raw,{
														arg nearest3;
														lines_dict.at("raw").put("pts",[self_i,id_to_idx.at(nearest3.asString)]);
														"raw nearest neighbor:\t\t\t\t%".format(nearest3).postln;

														~get_nearest.(id,~norm,{
															arg nearest0;
															lines_dict.at("norm").put("pts",[self_i,id_to_idx.at(nearest0.asString)]);
															"normalized nearest neighbor:\t\t%".format(nearest0).postln;

															~get_nearest.(id,~stand,{
																arg nearest1;
																lines_dict.at("stand").put("pts",[self_i,id_to_idx.at(nearest1.asString)]);
																"standardized nearest neighbor:\t\t%".format(nearest1).postln;

																~get_nearest.(id,~robust,{
																	arg nearest2;
																	lines_dict.at("robust").put("pts",[self_i,id_to_idx.at(nearest2.asString)]);
																	"robust scaler nearest neighbor:\t\t%".format(nearest2).postln;
																	defer{uv.refresh};
																});
															});
														});
													});
												});
											};
										};


										win.acceptsMouseOver_(true);

										win.front;

										uv.refresh;

									}.play(AppClock);
								});
							});
						});
					});
				});
			});
		});
	});
}.play;
)