// done without the need for busses
s.boot;
s.waitForBoot({
	SynthDef(\dumb_synth,{
		|freq = 440, amp = 1|
		var output = SinOsc.ar(freq,mul:amp);
		Out.ar(0,output ! 2);
	},[0.0,0.5]).send(s);

	s.sync;
	x = Synth(\dumb_synth);
	~changeFreq = { |freq,fadeTime=0.5|
		var oldAmp;
		fork {
			x.get(\amp,{|value| oldAmp = value;});
			s.sync;
			oldAmp.postln;
			s.sendBundle(nil,x.setMsg(\amp,0));
			s.sendBundle(0.5,x.setMsg(\freq,freq),
				x.setMsg(\amp,oldAmp));
		}
	};
});

x.set(\freq,400);
~changeFreq.(400);