s.options.device = "ASIO : Focusrite USB ASIO";
s.reboot;

(
SynthDef(\fmPseudo3D_music, {
    |out=0,
     carrierFreq=180, modFreq=90, modIndex=3,
     amp=0.18,
     chaos=0.35,
     width=0.9,
     room=0.35, damp=0.6,
     gate=1
    |

    var mod, car, sig;
    var azim, elev, front;
    var itd, left, right, ild;
    var backAmt, frontAmt;
    var upAmt, downAmt, notchHz;
    var env;

    env = EnvGen.kr(Env.asr(2.0, 1.0, 4.0), gate, doneAction: 2);

    azim  = LFDNoise3.kr(chaos);
    elev  = LFDNoise3.kr(chaos * 0.7);
    front = LFDNoise3.kr(chaos * 0.5);

    mod = SinOsc.ar(modFreq, 0, modIndex * modFreq);
    car = SinOsc.ar(carrierFreq + mod);

    itd = azim * 0.0006;
    left  = DelayC.ar(car, 0.01, itd.max(0));
    right = DelayC.ar(car, 0.01, itd.neg.max(0));

    ild = (azim * width).clip(-1, 1);
    left  = left  * (1 - ild);
    right = right * (1 + ild);

    sig = [left, right];

    backAmt  = front.linlin(-1, 1, 1, 0).clip(0, 1);
    frontAmt = 1 - backAmt;

    sig = BLowPass.ar(sig, (12000 * frontAmt + 1800 * backAmt), 0.6);
    sig = sig + (DelayC.ar(sig, 0.03, 0.012 + (backAmt * 0.012)) * (0.12 + backAmt * 0.18));

    upAmt = elev.linlin(-1, 1, 0, 1).clip(0, 1);
    downAmt = 1 - upAmt;

    notchHz = (6500 * downAmt + 9500 * upAmt);
    sig = BPeakEQ.ar(sig, notchHz, 0.7, -10);
    sig = BPeakEQ.ar(sig, 3500, 1.2, (upAmt * 3) - (downAmt * 2));

    sig = sig * (0.95 - (backAmt * 0.25));
    sig = FreeVerb2.ar(sig[0], sig[1], (room + backAmt * 0.35).clip(0, 1), 0.7, damp);

    Out.ar(out, sig * amp * env);
}).add;
)

(
x = Synth(\fmPseudo3D_music, [
    \amp, 0.10, \carrierFreq, 140, \modFreq, 70, \modIndex, 1.2,
    \chaos, 0.06, \width, 0.8, \room, 0.55, \damp, 0.7
]);

~centers = [110, 146, 196, 233, 277, 311];
~pickCenter = { ~centers.choose };

~drift = { |center, cents=40|
    center * (2 ** ((cents.rand2) / 1200));
};

~glideSteps = { |secs, steps=25, fn|
    steps.do { |i|
        fn.(i/(steps-1));
        (secs/steps).wait;
    }
};

r = Routine({
    var c = ~pickCenter.();
    var c2;

    20.do {
        x.set(
            \carrierFreq, ~drift.(c, 25),
            \modFreq,     ~drift.(c*0.5, 30).clip(20, 220),
            \modIndex,    exprand(0.4, 1.4),
            \chaos,       exprand(0.03, 0.10),
            \room,        exprand(0.50, 0.75),
            \width,       exprand(0.5, 0.9),
            \amp,         exprand(0.05, 0.11)
        );
        (exprand(0.4, 1.4)).wait;
    };

    35.do {
        x.set(
            \carrierFreq, ~drift.(c, 35),
            \modFreq,     ~drift.(c*0.75, 60).clip(25, 320),
            \modIndex,    exprand(1.2, 4.8),
            \chaos,       exprand(0.08, 0.28),
            \room,        exprand(0.25, 0.55),
            \width,       exprand(0.7, 1.0),
            \amp,         exprand(0.09, 0.17)
        );
        (exprand(0.25, 0.9)).wait;
        if (0.18.coin) { c = ~pickCenter.(); };
    };

    18.do {
        c2 = ~pickCenter.();
        ~glideSteps.(exprand(1.2, 2.8), 30, { |t|
            x.set(
                \carrierFreq, ~drift.(c.blend(c2, t), 60),
                \modFreq,     exprand(40, 420),
                \modIndex,    exprand(2.0, 7.5),
                \chaos,       exprand(0.18, 0.70),
                \room,        exprand(0.15, 0.45),
                \width,       exprand(0.6, 1.0),
                \amp,         exprand(0.08, 0.20)
            );
        });
        c = c2;
        (exprand(0.15, 0.6)).wait;
    };

    25.do {
        x.set(
            \carrierFreq, ~drift.(c, 18),
            \modFreq,     ~drift.(c*0.4, 25).clip(15, 180),
            \modIndex,    exprand(0.2, 1.2),
            \chaos,       exprand(0.02, 0.10),
            \room,        exprand(0.55, 0.85),
            \width,       exprand(0.4, 0.9),
            \amp,         exprand(0.02, 0.07)
        );
        (exprand(0.5, 1.6)).wait;
    };

    x.set(\gate, 0);
}).play;
)
r.stop; x.set(\gate, 0);