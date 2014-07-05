// This should write nothing into the buffer.

s.boot;

(
SynthDef(\write_const,{ |constant = 1.0,bus| Out.ar(bus,DC.ar(constant)) }).send(s);

SynthDef(\some_buf_wr,{ |bus,buf,sync| BufWr.ar(In.ar(bus),buf,sync) },[nil,nil,\ar]).send(s);
)

(
var writebus = Bus.audio, syncbus = Bus.audio, buf = Buffer.alloc(s,5),
constwrite = Synth(\write_const,[\bus,writebus]), syncwrite = Synth(\write_const,[\constant,-1,\bus,syncbus]), bufwrite = Synth(\some_buf_wr,[\bus,writebus,\buf,buf,\sync,syncbus],s,'addToTail');
buf.plot;
)
(
var writebus = Bus.audio, syncbus = Bus.audio, buf = Buffer.alloc(s,5,1);
buf.updateInfo({ |thisbuf|
/*	var constwrite = Synth(\write_const,[\bus,writebus]),
		syncwrite = Synth(\write_const,[\constant,1,\bus,syncbus]),
		bufwrite = Synth(\some_buf_wr,[\bus,writebus,\buf,buf,\sync,syncbus],s,'addToTail');*/
	thisbuf.numFrames.do({ |idx| thisbuf.get(idx,{|result| idx.postln; result.postln})});
});
)

b = Buffer.alloc(s,5,1,{ |buf| buf.get(2,{|val| val.postln;}); 1});
b.get(0,{|val| val.postln});
b.numFrames;
b.set(0,1);
b.get(0,{|val| val.postln;});

b = Buffer.new(s,5,1);
s.sendBundle(nil,b.allocMsg({ |buf| buf.set(0,1); buf.get(0,{|val| val.post;n}); 1}));
s.sendBundle(nil,b.allocMsg({ |buf| buf.numFrames.postln; 1}));
b.sendBundle(nil,b.allocMsg);

(
s.makeBundle(nil,{
	b = Buffer.alloc(s,5);
	s.sync;
	b.numFrames.do({|idx| b.get(idx,{"wtf".postln})});
	//b.numFrames.do({|idx| idx.postln});
	"huh?".postln
});
)
b.numFrames.do({|idx| b.get(idx,{|val| val.postln})});
b.numFrames;
(
{
	c = Condition.new;
	b = Buffer.alloc(s,1.0e+9,1);
	s.sync;
	10.do({|idx| b.get(idx,{|val| val.postln})});
}.fork.play;
)

s.quit;
s.boot;
b = Buffer.new(s, 44100);
b.query;
b.alloc;
b.allocMsg({|buf| buf.query; 1});
b.free;
b = Buffer.alloc(s,44100);
b.query;
b.free;
b = Buffer.alloc(s,44100,1,{|buf| buf.query; 1});
b.query;
