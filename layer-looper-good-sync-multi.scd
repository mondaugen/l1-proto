s.reboot;
~buf = Buffer.alloc(s, s.sampleRate * 2);

~buf.zero;
~buf.plot;

~syncBus = Bus.audio(s);

(
SynthDef(\rec_play_synced_tog,{ |buf, inBus, outBus, syncBus, oldAmp = 1, newAmp = 0, outAmp = 1, interpolation = 1|
	var input, output, sync;
	sync = In.ar(syncBus);
	input = BufRd.ar(1,buf,sync,interpolation: interpolation);
	output = (input * oldAmp) + (SoundIn.ar(inBus) * newAmp);
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
~rpSynth   = Synth.after(~syncSynth,\rec_play_synced_tog,[\buf,~buf,\inBus,0,\outBus,0,\syncBus,~syncBus]);
~syncSynth.set(\length,s.sampleRate * 2,\rate,2);
~outSpread = Synth.after(~rpSynth,\out_1_2);

~rpSynth.set(\newAmp,1);
~rpSynth.set(\newAmp,0);
~rpSynth.set(\oldAmp,0);
~rpSynth.set(\oldAmp,1);
