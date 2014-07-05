t = TempoClock.default;
a = [{"hello".postln; 2},{"losber".postln; 2}];
t.sched(0,a[0]);
a[0].clear;

s = Server.default;
s.reboot;
l = LayerLooperTest.new(s);
l.layerLooper.loopLength = 4;
t.sched(t.timeToNextBeat,{ l.layerLooper.recordLoop(0); nil });
l.layerLooper.hardKillLoop(0);
l.layerLooper.buffers[0].plot;
(0..7).do({|i| l.layerLooper.setLayerGain(i,-6)});
l.layerLooper.playingSynths[0].set(\gain,0);
l.layerLooper.setLayerGain(0,0);
l.free;
s.quit;

t = TempoClock.default.beats2secs(8) - TempoClock.default.beats2secs(0);
t = TempoClock.default;
~metroAmp = 0.1;

~continue = 1;
r = t.sched(t.timeToNextBeat,{
	s.makeBundle(nil,{
		{SinOsc.ar() * EnvGen.ar(Env.perc,doneAction:2) * ~metroAmp}.play(s) });
	~continue
});

r.stop;