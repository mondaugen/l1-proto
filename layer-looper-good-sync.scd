s.reboot;
~buf = Buffer.alloc(s, s.sampleRate * 2);

~buf.zero;
~buf.plot;

~syncBus = Bus.audio(s);

(
SynthDef(\rec_play_synced,{ |buf, inBus, outBus, syncBus|
	var input, output, sync;
	sync = In.ar(syncBus);
	input = BufRd.ar(1,buf,sync);
	output = input + SoundIn.ar(inBus);
	BufWr.ar(output,buf,sync);
	Out.ar(outBus,output);
}).send(s);
)

(
SynthDef(\sync_sig,{ |outBus, length, rate = 1|
	Out.ar(outBus, Phasor.ar(0, (s.sampleRate / length) * rate, 0, length));
}).send(s);
)

~syncSynth = Synth(\sync_sig,[\outBus,~syncBus,\length,~buf.numFrames]);
~rpSynth   = Synth.after(~syncSynth,\rec_play_synced,[\buf,~buf,\inBus,0,\outBus,0,\syncBus,~syncBus]);
~syncSynth.set(\length,s.sampleRate * 2);
~outSpread = Synth.after(~rpSynth,\out_1_2);