(
Routine{

	~source = Buffer.readChannel(s,FluidFilesPath("Tremblay-AaS-SynthTwoVoices-M.wav"),channels:[0]);
	//~source = Buffer.readChannel(s,FluidFilesPath("Constanzo-PreparedSnare-M.wav"),channels:[0]);
	// ~source = Buffer.readChannel(s,FluidFilesPath("Nicol-LoopE-M.wav"),channels:[0]);
	// ~source = Buffer.readChannel(s,FluidFilesPath("Tremblay-AaS-VoiceQC-B2K-M.wav"),channels:[0]);

	// ~target = Buffer.readChannel(s,FluidFilesPath("Tremblay-AaS-VoiceQC-B2K-M.wav"),channels:[0]);
	~target = Buffer.readChannel(s,FluidFilesPath("Nicol-LoopE-M.wav"),channels:[0]);

	~output = Buffer(s);

	s.sync;

	~cross = FluidBufNMFCross.process(s,~source,~target,~output,11,5,5,windowSize:1024);

	{
		FreeSelfWhenDone.kr(~cross.kr).poll;
	}.play;

	~cross.wait;

	"done".postln;

}.play;
)

(
{
	var sig = PlayBuf.ar(1,[~target,~output],BufRateScale.ir(~target),doneAction:2);
	sig * [-130,0].dbamp;
}.play;
)

(
var folder = thisProcess.nowExecutingPath.dirname+/+"outputs"+/+Date.localtime.stamp;
folder.mkdir;
~output.write(folder+/+"output.wav","wav");
~target.write(folder+/+"target.wav","wav");
~source.write(folder+/+"source.wav","wav");

~save_mel_spec = {
	arg buf, name, action;
	var mels = Buffer(s);
	fork({
		var fw, img;
		FluidBufMelBands.processBlocking(s,buf,features:mels,numBands:400,fftSize:4096,hopSize:128);
		s.sync;
		fw = FluidWaveform(imageBuffer:mels,imageColorScheme:1,imageColorScaling:1,bounds:Rect(0,0,1600,400));
		1.wait;
		img = Image.fromWindow(fw.parent);
		1.wait;
		img.write(folder+/+"%.jpg".format(name));
		fw.parent.close;
		1.wait;
		action.value;
	},AppClock);
};

~save_mel_spec.(~target,"target",{
	~save_mel_spec.(~output,"output",{
		~save_mel_spec.(~source,"source");
	});
});

)