(
s.waitForBoot{
	fork({
		var drums = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
		var n_components = 3;

		10.do{
			var bases = Buffer.loadCollection(s,513.collect{
				arg i;
				var kick = 0;
				var snare = 0;
				var hh = i.linlin(0,512,0.0,pi).sin;

				if(i < 10,{kick = 1});

				if((i > 10) && (i < 100),{snare = 1});

				[kick,snare,hh];
			}.flatten,3);

			s.sync;

			// process it:
			FluidBufNMF.processBlocking(s,drums,bases:bases,basesMode:1,components:n_components);
			bases.loadToFloatArray(action:{
				arg bases_array;
				var wa;
				bases_array = bases_array.clump(n_components).flop;
				wa = bases_array.collect{
					arg base;
					base.collect{
						arg mag, i;
						mag * i;
					}.sum;
				};

				if((wa[0] < wa[1]).and(wa[1] < wa[2]),{
					"good".postln;
				},{
					"bad".postln;
				});

				wa.postln;
				// defer{bases.plot};
			});
			s.sync;
		};
	});
};
)