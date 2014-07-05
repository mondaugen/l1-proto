s.boot;

(
// Synth for recording
SynthDef(\l_recorder,{|in,buf,len|
	RecordBuf.ar(In.ar(in) * EnvGen.ar(Env([0,1,1,0],[0,len,0]),doneAction:2),buf);
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

(
var recGroup = Group.new(s), playGroup = Group.new(recGroup,'addAfter'),
recBus = Bus.audio(s,1), playBus = Bus.audio(s,1), fbBus = Bus.audio(s,1);
var lInput = Synth.before(recGroup,\l_input,[\in,0,\out,recBus,\fb_in,fbBus]);
var lOutput = Synth.after(recGroup,\l_output,[\in,playBus,\out,0,\fb_out,fbBus]);
var buffers = [Buffer.alloc(s,s.sampleRate * 30.0), Buffer.alloc(s,s.sampleRate * 30.0)];
var fbGainBus = Bus.control(s);
var outSynth = Synth(\out_1_2,target:s,addAction:'addToTail');
var toFree = [fbBus,playBus,recBus,playGroup,recGroup,
	buffers[0],buffers[1],fbGainBus];
var curBuf = 0;

// Map fbGainBus to output feedback gain control
lOutput.map(\fb_gain,fbGainBus);

~lFreeAll = { toFree.do({|x| x.free}); };

~lRecord  = { |len = 1|
	var tempBuf = (curBuf + 1) % 2;
	"TempBuf: ".post; tempBuf.postln;
	Synth.after(recGroup,
		\l_recorder,[\in,recBus,\len,len,\buf,buffers[tempBuf]]).onFree(
		{curBuf = tempBuf});
};

~lPlay    = { |len = 1, rate = 1|
	"CurBuf: ".post; curBuf.postln;
	Synth.before(playGroup,\l_player,
		[\out,playBus,\len,len,\rate,rate,
			\buf,buffers[curBuf]]);
};

~lSetFB   = { |gain = -inf| fbGainBus.set(gain) };

~lGetCurBuf = { buffers[curBuf] };
)

~lRecord.(4);
~lPlay.();
~lFreeAll.();
~lSetFB.(-6);

~lGetCurBuf.().plot;

r = fork {
	loop {
		~lPlay.(4); 4.wait;

	}
};
r.stop;