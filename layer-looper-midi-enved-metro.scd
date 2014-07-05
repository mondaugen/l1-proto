// set up to work with your KORG nano kontrol
s.quit;
(
s.waitForBoot({
	// max loop time 30 seconds
	var totLenSec = 30;
	var bufs = Array.fill(10,{
		var buf;
		s.sampleRate.postln;
		buf = Buffer.alloc(s, s.sampleRate * totLenSec, 1);
		s.sync;
		buf.zero;
		buf;
	});

	var syncBus = Bus.audio(s);
	var syncSynth, rpSynths, outSpread, win, newAmpStates, oldAmpStates, outAmps, oaKeys, nasKeys,
	oasKeys, clearKeys, midiCcFunc, numLoops = 8, loopLenCcs, loopAmpCcs, rateCc = 22, loopPhaseCcs,
	feedbackCc = 13, metroSynth, metroSoundBuf;

	// Load metronome's sound
	metroSoundBuf = Buffer.read(s,"sounds/909CX_37_RM1_8.aif".resolveRelative);

	s.sync;

	SynthDef(\rec_play_synced_tog,{ |buf, inBus, outBus, syncBus, oldAmp = 1, newAmp = 0, outAmp = 1,
		interpolation = 1, mod = 44100, offset = 0, totalLen = 44100|
		var input, output, sync, env, envval;
		env = Env([0,1,1,0],[0.01,0.98,0.01],'sin');
		sync = In.ar(syncBus);
		sync = (((sync + offset) % mod)) % totalLen;
		envval = IEnvGen.ar(env,(sync / mod));
		input = BufRd.ar(1,buf,sync,interpolation: interpolation);
		output = (input * oldAmp) + (SoundIn.ar(inBus) * newAmp);
		BufWr.ar(output,buf,sync);
		Out.ar(outBus,output * outAmp * envval);
	},[0,0,0,0,0.1,0.1,0.1,0,0.1,0.1,0.1]).send(s);

	s.sync;

	// Metronome synth def
	SynthDef(\synced_metro,{ |buf, syncBus, outBus, mod = 44100, offset = 0, totalLen = 44100, outAmp = 1|
		var output, sync;
		sync = In.ar(syncBus);
		sync = (((sync + offset) % mod)) % totalLen;
		output = BufRd.ar(1,buf,sync,loop:0);
		Out.ar(outBus,output * outAmp);
	}).send(s);

	s.sync;

	SynthDef(\sync_sig,{ |outBus, length, rate = 1|
		Out.ar(outBus, Phasor.ar(0, rate, 0, length));
	}).send(s);

	s.sync;

	syncSynth = Synth(\sync_sig,[\outBus,syncBus,\length,bufs[0].numFrames]);
	metroSynth = Synth.after(syncSynth,\synced_metro,[\buf,metroSoundBuf,\syncBus,syncBus,\outBus,0,
		\mod,44100]); // clicks every 1/4 second
	rpSynths  = Array.fill(numLoops,{|idx|
		Synth.after(syncSynth,\rec_play_synced_tog,
			[\buf,bufs[idx],\inBus,0,\outBus,0,\syncBus,syncBus,\totalLen,s.sampleRate * totLenSec]);
	});
	outSpread = Synth.after(metroSynth,\out_1_2);
	win = Window.new;

	newAmpStates = Array.fill(numLoops,{ 0 });
	oldAmpStates = Array.fill(numLoops,{ 1 });
	outAmps      = Array.fill(numLoops,{ 1 });

	oaKeys  = [$1,$2,$3,$4,$5,$6,$7,$8,$9,$0];
	nasKeys = [$q,$w,$e,$r,$t,$y,$u,$i,$o,$p];
	oasKeys = [$a,$s,$d,$f,$g,$h,$j,$k,$l,$;];
	clearKeys = [$z,$x,$c,$v,$b,$n,$m,$,,$.,$/];
	win.view.keyDownAction = {
		|doc,char,mod,unicode,keycode,key|
		if(oaKeys.indexOf(char).notNil,{
			char.post;
			outAmps[oaKeys.indexOf(char)]  = (outAmps[oaKeys.indexOf(char)] + 1).mod(2);
			rpSynths[oaKeys.indexOf(char)].set(\outAmp,outAmps[oaKeys.indexOf(char)]);
			oaKeys.indexOf(char).post;
		});
		if(nasKeys.indexOf(char).notNil,{
			char.post;
			newAmpStates[nasKeys.indexOf(char)]  = (newAmpStates[nasKeys.indexOf(char)] + 1).mod(2);
			rpSynths[nasKeys.indexOf(char)].set(\newAmp,newAmpStates[nasKeys.indexOf(char)]);
			nasKeys.indexOf(char).post;
		});
		if(oasKeys.indexOf(char).notNil,{
			char.post;
			oldAmpStates[oasKeys.indexOf(char)]  = (oldAmpStates[oasKeys.indexOf(char)] + 1).mod(2);
			rpSynths[oasKeys.indexOf(char)].set(\oldAmp,oldAmpStates[oasKeys.indexOf(char)]);
			oasKeys.indexOf(char).post;
		});
		if(clearKeys.indexOf(char).notNil,{
			char.post;
			bufs[clearKeys.indexOf(char)].zero;
			clearKeys.indexOf(char).post;
		});
	};

	win.front;

	MIDIClient.init;
	MIDIIn.connectAll;

	loopLenCcs = [57,58,59,60,61,62,63,65];
	loopAmpCcs = [2,3,4,5,6,8,9,12,13];
	loopPhaseCcs = [42,43,50,51,52,53,54,55];

	midiCcFunc = MIDIFunc.cc({
		arg val, num, chan, src;
		if(loopLenCcs.indexOf(num).notNil,{
			var scaled = 2.pow(val.linlin(0,127,0,8).round);
			rpSynths[loopLenCcs.indexOf(num)].set(\mod,
				(s.sampleRate * totLenSec) / scaled);
			"Scaler: ".post; scaled.postln;
		});
		if(loopPhaseCcs.indexOf(num).notNil,{
			var scaled = val.linlin(0,127,0,127).round;
			rpSynths[loopPhaseCcs.indexOf(num)].set(\offset,
				-1 * (s.sampleRate * totLenSec) * (scaled / 128));
			"Phase: ".post; scaled.postln;
		});
		if(loopAmpCcs.indexOf(num).notNil,{
			rpSynths[loopAmpCcs.indexOf(num)].set(\outAmp,
				val.linlin(0,127,-96,0).dbamp);
		});
/*		if(num == rateCc,{
			var rate = val.linlin(0,127,0.25,3.0);
			syncSynth.set(\rate,rate); "Rate: ".post; rate.postln;
		});*/
		if(num == feedbackCc,{ "No feedback yet.".postln; });
	});
});
)

