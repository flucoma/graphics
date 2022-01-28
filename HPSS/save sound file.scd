~source = Buffer.read(s,FluidFilesPath("Tremblay-AaS-AcousticStrums-M.wav"),startFrame:560742,numFrames:388250);

~source.write(PathName(thisProcess.nowExecutingPath).pathOnly+/+"strums_excerpt.wav","wav");