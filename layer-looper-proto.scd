s.quit;
s.reboot;
s.boot;

(
// Synth for recording
SynthDef(\l_recorder,{|in,buf,len|
	RecordBuf.ar(SoundIn.ar(in) * EnvGen.ar(Env([0,1,1,0],[0,len,0]),doneAction:2),buf);
}).send(s);

// Synth for playing
SynthDef(\l_player,{|out, buf, len, attack=0.02, decay=0.02, rate=1.0|
	Out.ar(out,
		PlayBuf.ar(1,buf,rate)
		* EnvGen.ar(
			Env([0,1,1,0],[attack,len - attack - decay,decay],
				\welch),doneAction:2));
}).send(s);

// Synth for mixing input and feedback
SynthDef(\l_input,{|in,out,fb_in,fb_gain = 0|
	var sig = SoundIn.ar(in) + (InFeedback.ar(fb_in) * fb_gain.dbamp);
	Out.ar(out,sig);
}).send(s);

// Synth for mixing output and feedback
SynthDef(\l_output,{|in,out,fb_out,fb_gain = -inf|
	var sig = In.ar(in);
	Out.ar(fb_out,sig * (fb_gain.dbamp));
	Out.ar(out,sig);
}).send(s);
)

TempoClock.default.beats2secs(16)/.postln;

(
var tempoClock = TempoClock.default;
var loopLength = 4; // beats
var buffers = List[Buffer.alloc(s,
	s.sampleRate * (tempoClock.beats2secs(loopLength)))];
var playingLoops = List[];
~rate = 1.0;

~recordLoop = {
	var bundle = s.makeBundle(false,{
		"recording".postln;
		Synth(\l_recorder,[\in,0,
			\buf,buffers[buffers.size - 1],
			\len,tempoClock.beats2secs(loopLength)]);
	});
	s.makeBundle(nil,{
		var curIdx = playingLoops.size;
		var buf = buffers[buffers.size - 1];
		playingLoops.add([loopLength,{
			if(playingLoops[curIdx][0].notNil,{
				s.makeBundle(0.25,{
					"playing".postln;
					Synth(\l_player,[
						\rate,~rate,
						\out,0,
						\buf,buf,
						\len,tempoClock.beats2secs(loopLength)],s);
				});
				// Return time so it gets rescheduled
				playingLoops[curIdx][0];
			},{
				playingLoops.removeAt(curIdx);
				// Return nil so it doesn't get rescheduled
				nil;
			});
		}]);
		tempoClock.sched(loopLength,playingLoops[curIdx][1]);
		tempoClock.sched(loopLength,{
			buffers.add(Buffer.alloc(s,
				s.sampleRate * (tempoClock.beats2secs(loopLength))));
			nil; // Don't reschedule
		});
	},bundle);
};

~removeLastLoop = {
	playingLoops[playingLoops.size - 1][0] = nil;
	buffers.removeAt(buffers.size - 1).free;
};

~getCurrentBuffer = { buffers[buffers.size - 1]; };

~getLastBuffer = { buffers[buffers.size - 2] };
)
~rate = 1.00;
~removeLastLoop.();
~recordLoop.();
~getLastBuffer.().plot;
~metroAmp = 0.01;
t.sched(0,{
	s.makeBundle(0.25,{
		{SinOsc.ar() * EnvGen.ar(Env.perc) * ~metroAmp}.play(s) });
	1
});
Synth(\out_1_2,addAction:\addToTail);
