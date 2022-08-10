(
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs/%".format(Date.localtime.stamp);
s.waitForBoot{
	var src = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	var features, ds;

	s.sync;

	features = Buffer(s);
	FluidBufMFCC.processBlocking(s,src,features:features,startCoeff:1);
	ds = FluidDataSet(s).fromBuffer(features);

	outfolder.mkdir;

	["Manhattan","Euclidean","SquaredEuclidean","MinkowskiMax","MinkowskiMin","SymmetricKullbackLeibler"].do{
		arg name, dist_measure;
		var ds_transformed = FluidDataSet(s);
		"computing distance measure: % %".format(dist_measure, name).postln;
		FluidMDS(s,2,dist_measure).fitTransform(ds,ds_transformed);
		FluidNormalize(s).fitTransform(ds_transformed,ds_transformed);
		ds_transformed.dump({
			arg dict;
			fork({
				var img, fp;
				fp = FluidPlotter(bounds:Rect(0,0,900,900),dict:dict);
				1.wait;
				img = Image.fromWindow(fp);
				1.wait;
				img.write(outfolder+/+"%_%.png".format(dist_measure,name));
				1.wait;
				fp.close;
			},AppClock);
		});
		s.sync;
	};
};
)