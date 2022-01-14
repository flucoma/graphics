/*(
s.waitForBoot{
var guitar = Buffer.read(s,FluidFilesPath("Tremblay-AaS-AcousticStrums-M.wav"),startFrame:560742,numFrames:388250);
// var snare = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),startFrame:44100 * 1.157,numFrames:44100 * 0.291);
// var combined = Buffer(s);
var magsbuf = Buffer(s);
var stamp = Date.localtime.stamp;
var folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"hpss_outputs/%_just_bands".format(stamp);

folder.mkdir;

"hpss_functions.scd".loadRelative;

s.sync;

// FluidBufCompose.processBlocking(s,guitar,numFrames:guitar.sampleRate * 3,destination:combined,gain:-6.dbamp);
// FluidBufCompose.processBlocking(s,snare,destination:combined,destStartFrame:44100 * 1,destGain:1,gain:-6.dbamp);
FluidBufSTFT.processBlocking(s,guitar,magnitude:magsbuf);

s.sync;

magsbuf.postln;

magsbuf.loadToFloatArray(action:{
arg mags;
mags = mags.clump(magsbuf.numChannels).flop;
mags.postln;
mags.shape.postln;

defer{
~matrix_to_spectrogram.(mags,~colors).write(folder+/+"%_00_Original_Spectrogram.png".format(stamp),quality:100);
};
});

};
)*/

(
s.waitForBoot{
	Task{
		var source;
		var	magbuf = Buffer(s);
		var harmonicbuf = Buffer(s);
		var percussivebuf = Buffer(s);
		var stamp = Date.localtime.stamp;
		var folder = PathName(thisProcess.nowExecutingPath).pathOnly+/+"hpss_outputs/%_full_analysis".format(stamp);
		var writeFiles = true;

		var harm_filter_len = 51;//17
		var perc_filter_len = 91;//31

		if(writeFiles,{folder.mkdir});

		"hpss_functions.scd".loadRelative;

		Window.closeAll;
		// load a file to HPSS
		// ~source = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
		// ~source = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"),startFrame:44100 * 1.157,numFrames:44100 * 0.291);
		source = Buffer.read(s,FluidFilesPath("Tremblay-AaS-AcousticStrums-M.wav"),startFrame:560742,numFrames:388250);
		// check it if you want
		// FluidWaveform(~source,showSpectrogram:true,spectrogramColorScheme:1,showWaveform:false,bounds:Rect(0,0,1600,400));

		// get magnitudes

		s.sync;

		["Soft","Binary"].do{
			arg maskMode, i;
			FluidBufHPSS.processBlocking(s,source,maskingMode:i,harmonic:harmonicbuf,percussive:percussivebuf,harmFilterSize:harm_filter_len,percFilterSize:perc_filter_len);
			s.sync;
			if(writeFiles,{
				harmonicbuf.write(folder+/+"%_0%_harmonic_component_%_Mask.wav".format(stamp,i+1,maskMode),"wav");
				percussivebuf.write(folder+/+"%_0%_percussive_component_%_Mask.wav".format(stamp,i+1,maskMode),"wav");
			});
			s.sync;
		};

		FluidBufSTFT.processBlocking(s,source,magnitude:magbuf);

		s.sync;

		"stft done".postln;

		magbuf.loadToFloatArray(action:{
			arg mags, harm_frame, harm_frame_filtered, perc_frame, perc_frame_filtered;

			"mags: %".format(mags).postln;

			mags = mags.clump(magbuf.numChannels).flop;

			harm_frame = mags[40];
			harm_frame_filtered = ~median_filter.(harm_frame,harm_filter_len);
			Buffer.loadCollection(s,harm_frame.collect{arg h, i; [h,harm_frame_filtered[i]]}.flatten,2,{
				arg b;
				fork({
					var fw = FluidWaveform(featureBuffer:b,bounds:Rect(0,0,1200,300),normalizeFeaturesIndependently:false);
					if(writeFiles,{
						1.wait;
						fw.write(folder+/+"03_median_filter_on_a_row.png");
						fw.close;
					});
				},AppClock);
			});

			perc_frame = mags.flop[112];
			perc_frame_filtered = ~median_filter.(perc_frame,perc_filter_len);
			Buffer.loadCollection(s,perc_frame.collect{arg h, i; [h,perc_frame_filtered[i]]}.flatten,2,{
				arg b;

				fork({
					var fw = FluidWaveform(featureBuffer:b,bounds:Rect(0,0,1200,300),normalizeFeaturesIndependently:false);
					if(writeFiles,{
						1.wait;
						fw.write(folder+/+"04_median_filter_on_a_column.png");
						fw.close;
					});
				},AppClock);
			});

			if(writeFiles,{
				defer{
					var harm_enhanced, perc_enhanced, soft_masks, harm_ouptut_soft, perc_ouptut_soft, binary_masks, harm_ouptut_binary, perc_ouptut_binary;

					"mags shape: %".format(mags.shape).postln;
					~matrix_to_spectrogram.(mags,~colors).write(folder+/+"%_00_Original_Spectrogram.png".format(stamp),quality:100);

					harm_enhanced = ~make_harmonic_enhanced_spectrum.(mags,harm_filter_len); // 17
					"harm enhanced shape: %".format(harm_enhanced.shape).postln;
					~matrix_to_spectrogram.(harm_enhanced,~colors).write(folder+/+"%_03_Harmonic_Enhanced_Spectrogram_filterLen=%.png".format(stamp,harm_filter_len),quality:100);

					perc_enhanced = ~make_percussive_enhanced_spectrum.(mags,perc_filter_len); // 31
					~matrix_to_spectrogram.(perc_enhanced,~colors).write(folder+/+"%_04_Percussive_Enhanced_Spectrogram_filterLen=%.png".format(stamp,perc_filter_len),quality:100);

					soft_masks = ~make_masks_soft.(harm_enhanced,perc_enhanced);
					~matrix_to_mask.(soft_masks[0],~colors).write(folder+/+"%_05_Harmonic_Mask_(Soft).png".format(stamp),quality:100);
					~matrix_to_mask.(soft_masks[1],~colors).write(folder+/+"%_06_Percussive_Mask_(Soft).png".format(stamp),quality:100);
					harm_ouptut_soft = ~matrix_binOp.(mags,soft_masks[0],{arg a, b; a * b.min(1)});
					perc_ouptut_soft = ~matrix_binOp.(mags,soft_masks[1],{arg a, b; a * b.min(1)});
					~matrix_to_spectrogram.(harm_ouptut_soft,~colors).write(folder+/+"%_07_Harmonic_Output_(Soft_Mask).png".format(stamp),quality:100);
					~matrix_to_spectrogram.(perc_ouptut_soft,~colors).write(folder+/+"%_08_Percussive_Output_(Soft_Mask).png".format(stamp),quality:100);

					binary_masks = ~make_masks_binary.(harm_enhanced,perc_enhanced);
					~matrix_to_mask.(binary_masks[0],~colors_blue_yellow).write(folder+/+"%_09_Harmonic_Mask_(Binary).png".format(stamp),quality:100);
					~matrix_to_mask.(binary_masks[1],~colors_blue_yellow).write(folder+/+"%_10_Percussive_Mask_(Binary).png".format(stamp),quality:100);
					harm_ouptut_binary = ~matrix_binOp.(mags,binary_masks[0],{arg a, b; a * b.min(1)});
					perc_ouptut_binary = ~matrix_binOp.(mags,binary_masks[1],{arg a, b; a * b.min(1)});
					~matrix_to_spectrogram.(harm_ouptut_binary,~colors).write(folder+/+"%_11_Harmonic_Output_(Binary_Mask).png".format(stamp),quality:100);
					~matrix_to_spectrogram.(perc_ouptut_binary,~colors).write(folder+/+"%_12_Percussive_Output_(Binary_Mask).png".format(stamp),quality:100);
				}
			});
			"all done".postln;
		});
	}.play(AppClock);
};
);