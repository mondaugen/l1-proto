s.boot;
"sounds/tina_turner-whats_love_got_to_do_with.wav".resolveRelative;
b = Buffer.read(s,"sounds/tina_turner-whats_love_got_to_do_with.wav".resolveRelative);
b.plot;

x = { PlayBuf.ar(2,b,1,Phasor.ar(1,0.01,1,-1,1)) }.play(s);
b = Bus.control;
x = { |start = 3, freq = 1| var trig = Impulse.kr(freq); PlayBuf.ar(2,b,1,trig,startPos:(start * s.sampleRate)) }.play(s);
x.free;
x.set(\start,45);
x.set(\freq,0.78);

c = Buffer.alloc(s,s.sampleRate * 1);
y = { var sig = Impulse.ar(1); RecordBuf.ar(sig,c,doneAction:2); }.play(s);
y.free;
c.plot;
c.free;



(s.sampleRate * 1).do({|i| c.get(i,{|msg| msg.postln})});

SynthDef(\l_bufwr,{ |buf,inBus,inGain,phaseBus|
	BufWr.ar(In.ar(inBus) * inGain,buf,In.ar(phaseBus));
	0.0; // no output
}).send(s);

SynthDef(\l_syncplay,{ |buf,outBus,outGain,phaseBus,rate = 1.0|
	Out.ar(outBus,PlayBuf.ar(1,buf,rate,In.ar(phaseBus)) * outGain);
});

SynthDef(\l_syncwrite,{ |inBus,scale,period|
	