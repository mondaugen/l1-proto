s.quit;
s.reboot;
~bufs = Array.fill(10,{Buffer.alloc(s, s.sampleRate * 2, 1);});
~bufs.do({ |buf| buf.zero });

~syncBus = Bus.audio(s);

(
SynthDef(\rec_play_synced_tog,{ |buf, inBus, outBus, syncBus, oldAmp = 1, newAmp = 0, outAmp = 1, interpolation = 1, mod = 44100, offset = 0, totalLen = 44100|
	var input, output, sync;
	sync = In.ar(syncBus);
	sync = ((sync % mod) + offset) % totalLen;
	input = BufRd.ar(1,buf,sync,interpolation: interpolation);
	output = (input * oldAmp) + (SoundIn.ar(inBus) * newAmp);
	BufWr.ar(output,buf,sync);
	Out.ar(outBus,output * outAmp);
}).send(s);
)

(
SynthDef(\sync_sig,{ |outBus, length, rate = 1|
	Out.ar(outBus, Phasor.ar(0, rate, 0, length));
}).send(s);
)

~syncSynth = Synth(\sync_sig,[\outBus,~syncBus,\length,~bufs[0].numFrames]);
~rpSynths  = Array.fill(10,{|idx|
	Synth.after(~syncSynth,\rec_play_synced_tog,[\buf,~bufs[idx],\inBus,0,\outBus,0,\syncBus,~syncBus]);
});
// ~syncSynth.set(\length,s.sampleRate * 2,\rate,2);
~outSpread = Synth.after(~rpSynths[0],\out_1_2);

~win = Window.new;

~newAmpStates = Array.fill(10,{ 0 });
~oldAmpStates = Array.fill(10,{ 1 });
~outAmps      = Array.fill(10,{ 1 });

(
var oaKeys  = [$1,$2,$3,$4,$5,$6,$7,$8,$9,$0];
var nasKeys = [$q,$w,$e,$r,$t,$y,$u,$i,$o,$p];
var oasKeys = [$a,$s,$d,$f,$g,$h,$j,$k,$l,$;];
var clearKeys = [$z,$x,$c,$v,$b,$n,$m,$,,$.,$/];
~win.view.keyDownAction = {
	|doc,char,mod,unicode,keycode,key|
	if(oaKeys.indexOf(char).notNil,{
		char.post;
		~outAmps[oaKeys.indexOf(char)]  = (~outAmps[oaKeys.indexOf(char)] + 1).mod(2);
		~rpSynths[oaKeys.indexOf(char)].set(\outAmp,~outAmps[oaKeys.indexOf(char)]);
		oaKeys.indexOf(char).post;
	});
	if(nasKeys.indexOf(char).notNil,{
		char.post;
		~newAmpStates[nasKeys.indexOf(char)]  = (~newAmpStates[nasKeys.indexOf(char)] + 1).mod(2);
		~rpSynths[nasKeys.indexOf(char)].set(\newAmp,~newAmpStates[nasKeys.indexOf(char)]);
		nasKeys.indexOf(char).post;
	});
	if(oasKeys.indexOf(char).notNil,{
		char.post;
		~oldAmpStates[oasKeys.indexOf(char)]  = (~oldAmpStates[oasKeys.indexOf(char)] + 1).mod(2);
		~rpSynths[oasKeys.indexOf(char)].set(\oldAmp,~oldAmpStates[oasKeys.indexOf(char)]);
		oasKeys.indexOf(char).post;
	});
	if(clearKeys.indexOf(char).notNil,{
		char.post;
		~bufs[clearKeys.indexOf(char)].zero;
		clearKeys.indexOf(char).post;
	});
};
)

~win.front;


~rpSynths[0].set(\newAmp,1);
~rpSynths[0].set(\newAmp,0);
~rpSynths[0].set(\outAmp,1);
~rpSynths[0].set(\outAmp,0);
~rpSynths[0].set(\mod,44100 * 1);
~rpSynths[0].set(\totalLen,44100 * 2);
~rpSynths[5].set(\offset,22050 * 0.125);
~rpSynths[5].set(\mod,44100 * 2);

~rpSynths[0].dump;
~rpSynth.set(\oldAmp,0);
~rpSynth.set(\oldAmp,1);

~syncSynth.set(\rate,1);

a = 1;
a = (a + 1).mod(2);


