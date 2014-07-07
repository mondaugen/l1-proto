// set up to work with your KORG nano kontrol
// still working on getting the length in beats right...
s.quit;
(
s.waitForBoot({
	// max loop time 30 seconds
	var totLenSec = 30;
	var numLoops = 8;
	var syncBus = Bus.audio(s);
	var syncSynth, rpSynths, outSpread, win, newAmpStates, oldAmpStates, outAmps, oaKeys, nasKeys,
	oasKeys, clearKeys, midiCcFunc, loopLenCcs, loopAmpCcs, rateCc = 22, loopPhaseCcs, metroVolumeCc, // cc for metro volume
	tempoBPMCc, // cc for tempo
	lengthInBeatsCc, // cc for length in beats
	feedbackCc = 13, metroSynth, metroSoundBuf, lengthInBeats = 24, timePerBeat = 1, maxLengthInBeats = 48,
	controlFadeTime = 0.1, settingMetroArg = false;
	var bufs = Array.fill(numLoops,{
		var buf;
		s.sampleRate.postln;
		buf = Buffer.alloc(s, s.sampleRate * maxLengthInBeats, 1);
		s.sync;
		buf.zero;
		buf;
	});
	var lengthScalars = Array.fill(numLoops,{1});
	var settingRpArg = Array.fill(numLoops,false);

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
	},[0,0,0,0,0.1,0.1,0.1,0,0,0,0]).send(s);

	s.sync;

	// Metronome synth def
	SynthDef(\synced_metro,{ |buf, syncBus, outBus, mod = 44100, offset = 0, totalLen = 44100, outAmp = 1|
		var output, sync;
		sync = In.ar(syncBus);
		sync = (((sync + offset) % mod)) % totalLen;
		output = BufRd.ar(1,buf,sync,loop:0);
		Out.ar(outBus,output * outAmp);
	},[0,0,0,0,0,0,0.1]).send(s);

	s.sync;

	SynthDef(\sync_sig,{ |outBus, length, rate = 1|
		Out.ar(outBus, Phasor.ar(0, rate, 0, length));
	}).send(s);

	s.sync;

	syncSynth = Synth(\sync_sig,[\outBus,syncBus,\length, maxLengthInBeats * timePerBeat
		* (s.sampleRate)]);
	metroSynth = Synth.after(syncSynth,\synced_metro,[\buf,metroSoundBuf,\syncBus,syncBus,\outBus,0,
		\mod,s.sampleRate * timePerBeat]); // clicks every beat
	rpSynths  = Array.fill(numLoops,{|idx|
		Synth.after(syncSynth,\rec_play_synced_tog,
			[\buf,bufs[idx],\inBus,0,\outBus,0,\syncBus,syncBus,\totalLen,s.sampleRate
				* maxLengthInBeats * timePerBeat]);
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
	metroVolumeCc = 14; // cc for metro volume
	tempoBPMCc = 15; // cc for tempo
	lengthInBeatsCc = 16; // cc for length in beats

	midiCcFunc = MIDIFunc.cc({
		arg val, num, chan, src;
		var totalSyncLength;
		if(loopLenCcs.indexOf(num).notNil,{
			var scaled = 2.pow(val.linlin(0,127,0,8).round);
			lengthScalars[loopLenCcs.indexOf(num)] = scaled;
			"Scalar: ".post; scaled.postln;
		});
		if(num == metroVolumeCc,{ metroSynth.set(\outAmp,val.linlin(0,127,-96,0).dbamp) });
		if(num == tempoBPMCc,{
			var bpm = val.linlin(0,127,60,180);
			timePerBeat = 60.0 / bpm;
			"BMP: ".post; bpm.postln;
		});
		if(num == lengthInBeatsCc,{
			lengthInBeats = val.linlin(0,127,8,48).round;
			"Length In Beats: ".post; lengthInBeats.postln;
		});
		if(loopAmpCcs.indexOf(num).notNil,{
			rpSynths[loopAmpCcs.indexOf(num)].set(\outAmpz,
				val.linlin(0,127,-96,0).dbamp);
		});
		/* Every control change, update all values */
		totalSyncLength = s.sampleRate * lengthInBeats * timePerBeat;
		syncSynth.set(\length,totalSyncLength);
		if(settingMetroArg.not,{
			fork {
				// change values smoothly by fading out, changing the value, then fading in
				var metroOldAmp;
				settingMetroArg = true;
				metroSynth.get(\outAmp,{|val| metroOldAmp = val;});
				s.sync;
				"Metro out amp: ".post; metroOldAmp.postln;
				s.sendBundle(nil,metroSynth.setMsg(\outAmp,0));
				s.sendBundle(controlFadeTime,metroSynth.setMsg(\mod,totalSyncLength / lengthInBeats),
					metroSynth.setMsg(\outAmp,metroOldAmp));
				controlFadeTime.wait;
				settingMetroArg = false;
			};
		});
		rpSynths.do({|synth,idx|
			if(settingRpArg[idx].not,{
				fork {
					var rpOldAmp;
					settingRpArg[idx] = true;
					synth.get(\outAmp,{|val| rpOldAmp = val});
					s.sync;
					s.sendBundle(nil,synth.setMsg(\outAmp,0));
					s.sendBundle(controlFadeTime,synth.setMsg(\totalLength,totalSyncLength,
						\mod,totalSyncLength / lengthScalars[idx]),synth.setMsg(\outAmp,rpOldAmp));
					controlFadeTime.wait;
					settingRpArg[idx] = false;
				}
			});
		});

/*		if(num == rateCc,{
			var rate = val.linlin(0,127,0.25,3.0);
			syncSynth.set(\rate,rate); "Rate: ".post; rate.postln;
		});*/
/*		if(loopPhaseCcs.indexOf(num).notNil,{
			var scaled = val.linlin(0,127,0,127).round;
			rpSynths[loopPhaseCcs.indexOf(num)].set(\offset,
				-1 * (s.sampleRate * totLenSec) * (scaled / 128));
			"Phase: ".post; scaled.postln;
		});*/

		if(num == feedbackCc,{ "No feedback yet.".postln; });
	});
});
)

