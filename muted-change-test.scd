
s.scope;
(
fork {
	var jumpsynth, mutesynth,jumpbus,mutebus,mulsynth;
	SynthDef(\delayed_jump,{ |outbus,jumpto,delay|
		// max delay time 5 seconds
		var outsig = jumpto;
		Out.ar(outbus,DelayL.ar(outsig,5,delay));
	}).send(s);
	SynthDef(\temp_mute,{ |outbus,rampmid = 0.05,gate=0|
		Out.ar(outbus,EnvGen.ar(Env.new([1,0,1],[rampmid,rampmid]),gate));
	},[0,0,\tr]).send(s);
	SynthDef(\synth_mul,{|bus1,bus2,outbus|
		Out.ar(outbus,In.ar(bus1) * In.ar(bus2));
	}).send(s);
	jumpbus = Bus.audio(s);
	mutebus = Bus.audio(s);

	s.sync;

	mulsynth = Synth(\synth_mul,[\bus1,jumpbus,\bus2,mutebus,\outbus,0],s,\addToTail);

	s.sync;

	jumpsynth = Synth.basicNew(\delayed_jump,s);
	mutesynth = Synth.basicNew(\temp_mute,s);
	s.sendBundle(nil,jumpsynth.newMsg(s,[\delay,2,\jumpto,0.5,\outbus,jumpbus]),
		mutesynth.newMsg(s,[\rampmid,2,\gate,1,\outbus,mutebus]));
	~newval = { |val|
		s.sendBundle(nil,
			mutesynth.setMsg(\gate,0),
			jumpsynth.setMsg(\jumpto,val),
			mutesynth.setMsg(\gate,1));
	};
}
)
~newval.(-0.25);