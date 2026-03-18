s.options.device = "ASIO : Focusrite USB ASIO";

s.waitForBoot({

    // ============================================================
    // SYNTHDEF 1: eMass (Massas Sustentadas)
    //
    // - Substituí LeakDC por HPF (HighPass) em 30Hz: corte limpo de subgrave.
    // - Adicionei fasereal aleatória (Rand 0..2pi) para evitar cancelamento de fase.
    // - Limiter suave no final (tanh) para evitar picos que cortam o som.
    // ============================================================
    SynthDef(\eMass, {
        |out=0, freq=200, amp=0.1, pan=0,
         atk=2.0, susTime=3.0, rel=3.0,
         modRatio=1, modIndex=1,
         brightness=0,
         noiseAmt=0,
         dist=0
        |
        var mod, mod2, car, sig, env, noise;

        env = EnvGen.ar(
            Env.linen(atk, susTime, rel, 1, 0),
            doneAction: 2
        );

        // FM com Fase Aleatória (Rand): Evita que 3 synths somem fases iguais e cancelem/saturem
        mod2 = SinOsc.ar(freq * modRatio * 2, Rand(0, 2pi), brightness * freq * 0.5);
        mod  = SinOsc.ar(freq * modRatio + mod2, Rand(0, 2pi), modIndex * freq);
        car  = SinOsc.ar(freq + mod, Rand(0, 2pi));

        noise = LPF.ar(PinkNoise.ar(noiseAmt * 0.3), (freq * 3).max(120));
        sig = car + noise;

        // FILTRO PASSA-ALTA (HPF): Remove DC e subgraves inaudíveis (< 30Hz)
        sig = HPF.ar(sig, 30);
        
        // LIMITER SUAVE: Garante que nada exceda 1.0 (evita corte do driver)
        sig = sig.tanh;

        sig = LPF.ar(sig, 18000 / (1 + (dist * 15)));
        sig = Pan2.ar(sig, pan);

        Out.ar(out, sig * amp * env);
    }).add;

    // ============================================================
    // SYNTHDEF 2: eVoice (Impulsos)
    // ============================================================
    SynthDef(\eVoice, {
        |out=0, freq=200, amp=0.1, pan=0,
         atk=0.01, rel=1.0,
         modRatio=1, modIndex=1,
         brightness=0,
         noiseAmt=0,
         dist=0
        |
        var mod, mod2, car, sig, env, noise;

        env = EnvGen.ar(Env.perc(atk, rel, 1, -4), doneAction: 2);

        mod2 = SinOsc.ar(freq * modRatio * 2, Rand(0, 2pi), brightness * freq * 0.5);
        mod  = SinOsc.ar(freq * modRatio + mod2, Rand(0, 2pi), modIndex * freq);
        car  = SinOsc.ar(freq + mod, Rand(0, 2pi));

        noise = BPF.ar(WhiteNoise.ar(1), freq.max(100), 0.2 + (noiseAmt * 0.3));
        sig = (car * (1 - noiseAmt)) + (noise * noiseAmt * 2);

        sig = HPF.ar(sig, 50); // HPF aqui também
        sig = sig.tanh;

        sig = LPF.ar(sig, 18000 / (1 + (dist * 15)));
        sig = Pan2.ar(sig, pan);

        Out.ar(out, sig * amp * env);
    }).add;

    s.sync;
    "--- SynthDefs Carregados (HPF 30Hz + Random Phase) ---".postln;

    // ============================================================
    //  ÉTUDE 6 — "METAMORFOSES" (~3:00)
    // ============================================================

    ~etude6 = Pseq([

        // ZONA I — MATÉRIA (0:00 a 0:50)
        Pbind(\dur, Pseq([0.1], 1), \type, \rest,
            \log, Pfunc({ "--- Zona I: Matéria ---".postln })),

        Pfindur(50, Ppar([
            Pbind(
                \instrument, \eMass,
                \sendGate, false,
                \dur, Pwhite(3.0, 4.0),
                \freq, Pwhite(80.0, 130.0),
                \atk, 1.5, \susTime, 5.0, \rel, 4.5,
                \modRatio, 1,
                \modIndex, Pseg([0.1, 2.0], [60], \exp),
                \brightness, 0.3,
                \amp, Pseg([0.02, 0.07], [60], \exp),
                \pan, Pwhite(-0.3, 0.3),
                \dist, 0.35
            ),
            Pbind(
                \instrument, \eMass,
                \sendGate, false,
                \dur, Pwhite(3.5, 5.0),
                \freq, Pwhite(83.0, 135.0),
                \atk, 2.0, \susTime, 5.0, \rel, 4.0,
                \modRatio, Pwhite(0.995, 1.005),
                \modIndex, Pseg([0.1, 1.5], [60], \exp),
                \brightness, 0.2,
                \amp, Pseg([0.01, 0.06], [60], \exp),
                \pan, Pwhite(-0.5, 0.5),
                \dist, 0.45
            ),
            Pbind(
                \instrument, \eVoice,
                \dur, Pwhite(8.0, 14.0),
                \atk, 1.0, \rel, 2.5,
                \freq, Pwhite(800.0, 2500.0),
                \modRatio, 1, \modIndex, 0.2,
                \noiseAmt, 0.2,
                \amp, Pseg([0.001, 0.03], [60], \exp),
                \pan, Pwhite(-0.8, 0.8),
                \dist, 0.7
            )
        ])),

        // ZONA II — IMPULSOS (0:50 a 1:35)
        Pbind(\dur, Pseq([0.1], 1), \type, \rest,
            \log, Pfunc({ "--- Zona II: Impulsos ---".postln })),

        Pfindur(45, Ppar([
            Pbind(
                \instrument, \eVoice,
                \dur, Pbrown(0.15, 0.8, 0.08),
                \atk, 0.001,
                \rel, Pwhite(0.08, 0.25),
                \freq, Pwhite(300.0, 5000.0),
                \modRatio, Prand([1.41, 2.71, 3.14, 0.618], inf),
                \modIndex, Pwhite(2.0, 6.0),
                \brightness, Pwhite(0.0, 1.5),
                \noiseAmt, Pwhite(0.0, 0.35),
                \amp, Pexprand(0.02, 0.08),
                \pan, Pwhite(-1.0, 1.0),
                \dist, Pwhite(0.1, 0.7)
            ),
            Pbind(
                \instrument, \eMass,
                \sendGate, false,
                \dur, Pwhite(2.5, 4.0),
                \freq, Pwhite(70.0, 120.0),
                \atk, 0.3, \susTime, 2.0, \rel, 2.5,
                \modRatio, 0.5,
                \modIndex, Pwhite(1.5, 3.5),
                \brightness, 0.5,
                \amp, Pwhite(0.04, 0.08),
                \pan, Pbrown(-0.7, 0.7, 0.2),
                \dist, 0.3
            )
        ])),

        // ZONA III — FLUXO (1:35 a 2:20)
        Pbind(\dur, Pseq([0.1], 1), \type, \rest,
            \log, Pfunc({ "--- Zona III: Fluxo ---".postln })),

        Pfindur(45, Ppar([
            Pbind(
                \instrument, \eMass,
                \sendGate, false,
                \dur, Pwhite(2.0, 3.5),
                \freq, Pseg([120, 1000, 90, 400], [20, 20, 20], \exp),
                \atk, 1.0, \susTime, 3.0, \rel, 3.0,
                \modRatio, Pseg([1, 2.5, 0.5, 1], [20, 20, 20], \lin),
                \modIndex, Pseg([0.5, 3.5, 0.5, 2], [20, 20, 20], \lin),
                \brightness, Pseg([0.0, 2.0, 0.0, 1.0], [20, 20, 20], \sin),
                \noiseAmt, Pseg([0.0, 0.4, 0.0, 0.2], [20, 20, 20], \sin),
                \amp, 0.1,
                \pan, Pseg([-0.7, 0.7, -0.4, 0.4], [20, 20, 20], \sin),
                \dist, Pseg([0.2, 0.6, 0.1, 0.4], [20, 20, 20], \sin)
            ),
            Pbind(
                \instrument, \eVoice,
                \dur, Pwhite(0.2, 0.5),
                \atk, 0.001, \rel, 0.08,
                \freq, Pwhite(1200.0, 4000.0),
                \modRatio, 2.71, \modIndex, 0.8,
                \noiseAmt, 0.4,
                \amp, Pseg([0.005, 0.03, 0.005], [25, 25], \sin),
                \pan, Pwhite(-1.0, 1.0), \dist, 0.6
            )
        ])),

        // ZONA IV — DISSOLUÇÃO (2:20 a 3:00)
        Pbind(\dur, Pseq([0.1], 1), \type, \rest,
            \log, Pfunc({ "--- Zona IV: Dissolução ---".postln })),

        Pfindur(40, Ppar([
            Pbind(
                \instrument, \eMass,
                \sendGate, false,
                \dur, Pseq([2, 3, 5, 7, 11, 13], 1),
                \freq, Pseq([100, 250, 120, 600, 90, 1200], 1),
                \atk, 0.5, \susTime, 3.0, \rel, 4.0,
                \modRatio, 1, \modIndex, 0.5,
                \noiseAmt, Pseg([0.0, 0.35], [50], \lin),
                \amp, Pgeom(0.08, 0.65, inf),
                \pan, Pseq([0, -0.3, 0.2, -0.5, 0.1, 0], 1),
                \dist, Pseg([0.3, 0.95], [50], \lin)
            ),
            Pbind(
                \instrument, \eVoice,
                \dur, Pseq([3, 5, 8, 13], 1),
                \atk, 0.001, \rel, 0.15,
                \freq, Pwhite(1500.0, 4000.0),
                \modRatio, 1.41, \modIndex, 1.5,
                \amp, Pgeom(0.05, 0.5, inf),
                \pan, Pwhite(-0.4, 0.4), \dist, 0.7
            )
        ])),

        Pbind(\dur, Pseq([0.1], 1), \type, \rest,
            \log, Pfunc({ "--- Fim da Étude 6 ---".postln }))

    ]).play;

});

// Para parar:
// ~etude6.stop;
