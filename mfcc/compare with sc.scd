b = Buffer.read(s,FluidFilesPath("Olencki-TenTromboneLongTones-M.wav"));

(
{
	var sig = PlayBuf.ar(1,b,BufRateScale.kr(b),loop:1);
	//var fm = FluidMFCC.kr(sig,maxNumCoeffs:13,).poll(label:"f");
	//var sm = MFCC.kr(FFT(LocalBuf(1024),sig)).poll(label:"s");
	var mb = FluidMelBands.kr(sig,maxNumBands:40).poll(label:"m");
}.play
)