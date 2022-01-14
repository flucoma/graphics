p = PathName(thisProcess.nowExecutingPath).pathOnly+/+"../hpss_functions.scd";
File.exists(p)

p.load



~median_filter.(Array.fill(200,{arg i; rrand(0.0,1.0)}));