

// make something to analyze
(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
s.options.numWireBufs_(512);
s.waitForBoot{
	var src = Buffer.read(s,"/Users/macprocomputer/Desktop/scspear/pathetique_scspear.wav");
	var clicks = Buffer.read(s,FluidFilesPath("Tremblay-UW-ComplexDescent-M.wav"));
	var recbuf = Buffer.alloc(s,s.sampleRate * 30);

	s.sync;

	{
		var phs = Phasor.kr(0,0.0008,10,src.numFrames);
		var data = BufRd.kr(src.numChannels,src,phs,1,4);
		var freqs = data[..((src.numChannels/2)-1).asInteger];
		var amps = data[(src.numChannels/2).asInteger..];
		var sig = SinOsc.ar(freqs * 0.9,0,amps).sum;

		var trig = Dust.kr(0.3);
		var dur = TRand.kr(0.03,0.08,trig);
		sig = sig + TGrains.ar(1,trig,clicks,4,TRand.kr(dur/2,BufDur.ir(clicks)-(dur/2),trig),dur,0,1);
		RecordBuf.ar(sig,recbuf,loop:0,doneAction:2);
		sig.dup
	}.play;

	recbuf.duration.wait;
	1.wait;

	outfolder.mkdir;

	recbuf.write(outfolder+/+"src.wav","wav");
};
)

//================================================================

(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
s.waitForBoot{
	var src = Buffer.read(s,"/Users/macprocomputer/dev/flucoma/graphics/outliers/sus_with_clicks/outputs/220510_110847/src.wav");
	var ds = FluidDataSet(s);
	var ds_plot = FluidDataSet(s);
	var umap = FluidUMAP(s);
	var normer = FluidNormalize(s);
	var mfccs = Buffer(s);

	s.sync;

	FluidBufMFCC.processBlocking(s,src,features:mfccs);
	ds.fromBuffer(mfccs);
	// kmeans.fitPredict(ds,labels);
	outfolder.mkdir;
	ds.write(outfolder+/+"sus_with_clicks_ds.json");
	ds.print;
	umap.fitTransform(ds,ds_plot);
	normer.fitTransform(ds_plot,ds_plot);
	// tree.fit(ds_plot);
	ds_plot.write(outfolder+/+"sus_with_clicks_ds_plot.json");
}
)

(
s.waitForBoot{
	var folder = "/Users/macprocomputer/dev/flucoma/graphics/outliers/sus_with_clicks/outputs/220510_112055/";
	var xybuf = Buffer.alloc(s,2);
	var ds = FluidDataSet(s).read(folder+/+"sus_with_clicks_ds.json");
	var ds_plot = FluidDataSet(s).read(folder+/+"sus_with_clicks_ds_plot.json");
	var tree = FluidKDTree(s).fit(ds_plot);
	var mfccbuf = Buffer.alloc(s,13);

	s.sync;

	ds_plot.dump({
		arg dict;
		/*labels.dump({
		arg labelsdict;*/
		defer{FluidPlotter(dict:dict,bounds:Rect(0,0,800,800),mouseMoveAction:{
			arg view, x, y;
			xybuf.setn(0,[x,y]);
			tree.kNearest(xybuf,1,{
				arg id;
				ds.getPoint(id,mfccbuf,{
					mfccbuf.loadToFloatArray(action:{
						arg mfcc;
						mfcc.postln;
					});
				});
			});
		})};//.categories_(labelsdict)};
		// });
	});
}
)

(
s.waitForBoot{
	var folder = "/Users/macprocomputer/dev/flucoma/graphics/outliers/sus_with_clicks/outputs/220510_112055/";
	var ds = FluidDataSet(s).read(folder+/+"sus_with_clicks_ds.json");
	var ds_plot = FluidDataSet(s).read(folder+/+"sus_with_clicks_ds_plot.json");

	ds.dump({
		arg dict;
		ds_plot.dump({
			arg plot_dict;

			defer{

				FluidPlotter(dict:plot_dict.deepCopy,bounds:Rect(0,0,800,800),mouseMoveAction:{
					arg view, x, y;

				});

				dict["data"].keysValuesDo{
					arg k, v;
					if(v[0] > -150){
						plot_dict["data"][k] = nil;
					};
				};

				FluidPlotter(dict:plot_dict,bounds:Rect(0,0,800,800),mouseMoveAction:{
					arg view, x, y;

				})
			};
		});
	});
}
)