(
var stamp = Date.localtime.stamp;
var outfolder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+stamp;
s.waitForBoot{
	var buf, features, fw, img;

	buf = Buffer.read(s,FluidFilesPath("Olencki-TenTromboneLongTones-M.wav"));
	features = Buffer(s);

	s.sync;

	FluidBufPitch.processBlocking(s,buf,features:features,windowSize:4096,action:{"done".postln});

	s.sync;

	fw = FluidWaveform(buf,featuresBuffer:features,bounds:Rect(0,0,1600,400),lineWidth:2,stackFeatures:true);

	s.sync;
	1.wait;

	img = Image.fromWindow(fw.win);

	outfolder.mkdir;

	img.write(outfolder+/+"%_pitch.png".format(stamp),"png",100);

	fw.close;

	"done done".postln;
}
)
	