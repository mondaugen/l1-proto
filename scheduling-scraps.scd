s.boot;
v = 4;
f = { if(v.notNil,{"Call me maybe...".postln}); v };
t = TempoClock.default;
t.schedAbs(t.nextTimeOnGrid,f);
v = nil;

t.queue.postln;
x = t.seconds;
t.schedAbs(x + 60,{ "hello".postln });
t.schedAbs(x + 60,{ "hello again".postln;});
t.schedAbs(x + 60,{ "and again, hello".postln;});

~drum808_init.();
~p808_rt.(1);
~ts = TaskSequencer.new;
8.do({ |i| ~ts.sequence[i] = { ~p808_rt.(1,length:0.1); }; });
t.play(~ts.task);
~ts.task.play;
~ts.sequence[4] = { ~p808_rt.(4) };
~ts.sequence[7] = { ~p808_rt.(10) };
~ts.length = 1;

~ts = TaskListSequencer.new;
8.do({ |i| ~ts.sequence[i].add({ ~p808_rt.(1,length:0.1); }); });
~ts.sequence[4].add({ ~p808_rt.(4) });
~ts.sequence[4].add({ |tidx,lidx,list| ~p808_rt.(4); list.removeAt(lidx); });
~ts.sequence[4].removeAt(1);
~ts.task.play;

(
var a;
a = List[1, 2, 3, 4];
a.remove(3);
a;
)