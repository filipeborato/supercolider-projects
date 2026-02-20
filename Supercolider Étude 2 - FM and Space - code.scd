s.options.device = "ASIO : Focusrite USB ASIO";
s.reboot;

(
SynthDef(\fmPseudo3D_richTimbre, {
    |out=0,
     carrierFreq=180, modFreq=90, modIndex=3,
     amp=0.18,
     chaos=0.35,
     width=0.9,
     room=0.35, damp=0.6,
     gate=1,
     brightness=0.5,
     harmonics=0.6,
     attackTime=0.05
    |

    var mod1, mod2, car, noise, timbre, sig;
    var azim, elev, front;
    var itd, left, right, ild;
    var upAmt, downAmt, notchHz;
    var env, timbralEnv;
    var cf, mf, mi, br, hm, bAmt, fAmt;
    
    // Suavização de parâmetros para eliminar clicks durante mudanças (x.set)
    cf = carrierFreq.lag(0.15);
    mf = modFreq.lag(0.15);
    mi = modIndex.lag(0.15);
    br = brightness.lag(0.2);
    hm = harmonics.lag(0.2);

    // Envelope ADSR para evitar pop inicial e final
    env = EnvGen.kr(Env.adsr(attackTime, 0.3, 0.8, 2.0), gate, doneAction: 2);

    timbralEnv = EnvGen.kr(Env([0.2, 1, 0.7, 0.4], [2, 3, 4], \sine), gate);

    azim  = LFDNoise3.kr(chaos);
    elev  = LFDNoise3.kr(chaos * 0.7);
    front = LFDNoise3.kr(chaos * 0.5);

    mod1 = SinOsc.ar(mf * 0.5, 0, mi * mf * 0.5 * hm);
    
    mod2 = SinOsc.ar(
        mf + mod1 + (SinOsc.ar(mf * 1.5) * mf * 0.3 * timbralEnv),
        0,
        mi * mf * timbralEnv * (cf.linlin(40, 400, 0.4, 1.0).clip(0.3, 1.0))
    );
    
    car = SinOsc.ar(cf + mod2);
    car = car + (LFTri.ar(cf + (mod2 * 0.7)) * 0.3 * hm);
    
    noise = BPF.ar(
        PinkNoise.ar(0.08 * br),
        cf * (1 + (LFNoise1.kr(0.3) * 0.2)),
        0.15
    );
    
    timbre = (car * (1 - (br * 0.3))) + (noise * timbralEnv);

    itd = azim * 0.0006;
    left  = DelayC.ar(timbre, 0.01, itd.max(0));
    right = DelayC.ar(timbre, 0.01, itd.neg.max(0));

    ild = (azim * width).clip(-1, 1);
    left  = left  * (1 - ild);
    right = right * (1 + ild);

    sig = [left, right];

    // Suavização das variáveis de profundidade para evitar saltos nos filtros
    bAmt = front.linlin(-1, 1, 1, 0).clip(0, 1).lag(0.2);
    fAmt = 1 - bAmt;

    // Filtros de profundidade e elevação usando as variáveis suavizadas
    sig = BLowPass.ar(sig, (12000 * fAmt + 1800 * bAmt), 0.6);
    sig = sig + (DelayC.ar(sig, 0.03, 0.012 + (bAmt * 0.012)) * (0.12 + bAmt * 0.18));

    upAmt = elev.linlin(-1, 1, 0, 1).clip(0, 1).lag(0.2);
    downAmt = 1 - upAmt;

    notchHz = (6500 * downAmt + 9500 * upAmt);
    sig = BPeakEQ.ar(sig, notchHz, 0.7, -10);
    sig = BPeakEQ.ar(sig, 3500, 1.2, (upAmt * 3) - (downAmt * 2));

    sig = sig * (0.95 - (bAmt * 0.25));
    sig = FreeVerb2.ar(sig[0], sig[1], (room + bAmt * 0.35).clip(0, 1), 0.7, damp);

    Out.ar(out, sig * amp * env);
}).add;
)

// ============================================================
// COMPOSIÇÃO ÉTUDE 2: NUVENS ESPECTRAIS E ESPACIALIZAÇÃO CAÓTICA
// Foco em texturas evolutivas e densidade, diferente da Étude 1.
// ============================================================

(
x = Synth(\fmPseudo3D_richTimbre, [
    \amp, 0.06, \carrierFreq, 110, \modFreq, 55, \modIndex, 0.8,
    \chaos, 0.05, \width, 0.9, \room, 0.8, \damp, 0.4,
    \brightness, 0.3, \harmonics, 0.4, \attackTime, 0.1
]);

~centers = [110, 130.81, 146.83, 164.81, 196, 220].mirror; 

~glide = { |secs, steps=30, fn|
    steps.do { |i|
        fn.(i/(steps-1));
        (secs/steps).wait;
    }
};

r = Routine({
    var c = ~centers[0];
    
    // FASE 1: Gênese (Drones suaves e escuros)
    "--- Fase 1: Gênese ---".postln;
    8.do { |i|
        x.set(
            \carrierFreq, c * [1, 0.5, 1.5].choose,
            \modFreq, c * [0.5, 0.25].choose,
            \modIndex, rrand(0.2, 1.2),
            \brightness, 0.1 + (i * 0.05),
            \amp, 0.05 + (i * 0.01)
        );
        rrand(2.0, 4.0).wait;
        c = ~centers.choose;
    };

    // FASE 2: Expansão Caótica (Aumento de brilho e movimento espacial)
    "--- Fase 2: Expansão ---".postln;
    15.do { |i|
        x.set(
            \carrierFreq, c * rrand(0.9, 1.1),
            \modFreq, rrand(40, 400),
            \modIndex, rrand(1.5, 4.0),
            \chaos, 0.1 + (i * 0.02),
            \brightness, 0.4 + (i * 0.02),
            \harmonics, 0.5 + (i * 0.02),
            \amp, 0.1 + (i * 0.005)
        );
        rrand(0.8, 2.0).wait;
        if(0.3.coin) { c = ~centers.choose };
    };

    // FASE 3: Enxame Espectral (Glissandos densos e FM agressiva)
    "--- Fase 3: Enxame ---".postln;
    12.do {
        var nextC = ~centers.choose;
        ~glide.(rrand(1.5, 3.0), 40, { |t|
            x.set(
                \carrierFreq, c.blend(nextC, t),
                \modFreq, exprand(100, 1000),
                \modIndex, exprand(3.0, 8.0),
                \chaos, 0.5,
                \brightness, 0.8,
                \amp, 0.12
            );
        });
        c = nextC;
        rrand(0.1, 0.4).wait;
    };

    // FASE 4: Dissipação (Retorno ao silêncio e frequências graves)
    "--- Fase 4: Dissipação ---".postln;
    10.do { |i|
        x.set(
            \carrierFreq, [55, 110, 82.4].choose,
            \modIndex, 0.5,
            \brightness, 0.4 * (1 - (i/10)),
            \amp, 0.1 * (1 - (i/10)),
            \chaos, 0.05
        );
        rrand(1.5, 3.0).wait;
    };

    x.set(\gate, 0);
    "--- Fim da Étude 2 ---".postln;
}).play;
)

r.stop; x.set(\gate, 0);
