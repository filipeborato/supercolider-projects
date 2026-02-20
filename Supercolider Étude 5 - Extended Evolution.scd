s.options.device = "ASIO : Focusrite USB ASIO";

// Garantir que o servidor inicia antes de executar o resto
s.waitForBoot({

    // ============================================================
    // SYNTHDEF: FM3D_CLOUD_V2 (Granular Avançado)
    // ============================================================
    SynthDef(\fmPseudo3D_cloud_v2, {
        |out=0,
         freq=110, modRatio=0.5, modIndex=3,
         amp=0.1,
         azim=0,        // -1 (esq) a +1 (dir)
         elev=0,        // -1 (baixo) a +1 (cima)
         dist=0,        // 0 (perto) a 1 (longe)
         atk=0.1, rel=1.5,
         panNoise=0.0,   // jitter espacial extra
         shape=0.0,      // 0 = senoidal pura, 1 = distorção/feedback
         noiseAmt=0.0    // mistura de ruído para textura "areia"
        |

        var mod, car, sig, env, noiseSig;
        var itd, left, right, ild;
        var bAmt, fAmt, upAmt, downAmt, notchHz;
        var localAzim, room, damp;

        // Envelope Percussivo
        env = EnvGen.ar(Env.perc(atk, rel, 1, -4), doneAction: 2);

        // Jitter espacial
        localAzim = (azim + LFNoise1.kr(10, panNoise)).clip(-1, 1);

        // Síntese FM com Shaping
        mod = SinOsc.ar(freq * modRatio, 0, modIndex * (freq * modRatio));
        // Feedback FM sutil baseado em 'shape'
        mod = mod + (SinOsc.ar(freq * modRatio * 2) * shape * modIndex * 0.5);

        car = SinOsc.ar(freq + mod);
        // Waveshaping no carrier para adicionar harmônicos extras
        car = (car * (1 - (shape * 0.5))) + (car.tanh * shape * 0.8);

        // Adiciona camada de ruído "colorido"
        noiseSig = BPF.ar(PinkNoise.ar(1), freq * 4, 0.5) * noiseAmt;
        car = car + noiseSig;

        // Filtro de Distância
        car = LPF.ar(car, 18000 / (1 + (dist * 12)));
        car = HPF.ar(car, 50 * dist); // Corta graves se muito longe

        // --- Espacialização Pseudo-3D ---
        itd = localAzim * 0.00065;
        left  = DelayC.ar(car, 0.01, itd.max(0));
        right = DelayC.ar(car, 0.01, itd.neg.max(0));

        ild = (localAzim * 0.75).clip(-1, 1);
        left  = left  * (1 - ild);
        right = right * (1 + ild);
        sig = [left, right];

        // Profundidade e Elevação (Filtros HRTF simulados)
        bAmt = dist.clip(0, 1);
        fAmt = 1 - bAmt;
        upAmt = elev.clip(0, 1);
        downAmt = (1 - upAmt).max(0);

        notchHz = (6000 * downAmt + 11000 * upAmt).clip(4000, 12000);
        sig = BPeakEQ.ar(sig, notchHz, 0.7, -10); // Notch principal
        sig = BPeakEQ.ar(sig, 3000, 1.0, (upAmt * 2.5) - (downAmt * 1.5)); // Presença média

        // Reverb Integrado
        room = 0.2 + (dist * 0.7);
        damp = 0.4 + (shape * 0.4); // Mais brilhante se tiver mais shape
        sig = FreeVerb2.ar(sig[0], sig[1], room * 0.35, room, damp);

        Out.ar(out, sig * amp * env);
    }).add;

    // Aguarda o SynthDef ser carregado no servidor
    s.sync;

    "--- SynthDef Carregado. Iniciando Composição ---".postln;

    // ============================================================
    // COMPOSIÇÃO: ÉTUDE 5 - "EVOLUÇÃO ESTENDIDA" (~3:00)
    // Intro -> Chuva -> Tempestade -> Coda
    // ============================================================

    // Escalas Harmônicas
    ~scaleNebula = [110, 146.83, 164.81, 196, 220]; // Pentatônica A (suspensa)
    ~scaleRain   = [110, 123.47, 130.81, 146.83, 164.81, 174.61, 196]; // Modo Eólio/Dórico híbrido
    ~scaleStorm  = [55, 69.30, 77.78, 87.31, 103.83, 110, 155.56, 311.13]; // Cromático/Diminuído
    ~scaleCoda   = [55, 110, 164.81, 220, 330]; // Acorde A Major muito aberto

    ~etude5 = Pseq([
        // ============================================================
        // I. INTRO: NÉBULA (0:00 - 0:45)
        // ============================================================
        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- I. Intro: Nebula ---".postln })),
        Pfindur(45, Pbind(
            \instrument, \fmPseudo3D_cloud_v2,
            \dur, Pwhite(1.5, 3.5),       // Muito lento
            \atk, Pwhite(2.0, 4.0),       // Ataques muito lentos
            \rel, Pwhite(4.0, 7.0),       // Decays longos (pads)
            \freq, Pxrand(~scaleNebula, inf),
            \modRatio, 1.0,               // Harmônico simples
            \modIndex, Pwhite(0.2, 0.8),  // Índice baixo (quase senoidal)
            \shape, 0,
            \noiseAmt, 0.05,              // Leve "sujeira"
            \amp, Pwhite(0.08, 0.12),
            \azim, Pwhite(-0.3, 0.3),     // Centro
            \dist, Pwhite(0.4, 0.7),      // Médio-Longe
            \elev, 0,
            \panNoise, 0.1
        )),

        // ============================================================
        // II. DESENVOLVIMENTO: CHUVA ESTRUTURADA (0:45 - 1:30)
        // ============================================================
        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- II. Development: Rain ---".postln })),
        Pfindur(45, Pbind(
            \instrument, \fmPseudo3D_cloud_v2,
            \dur, Pwhite(0.1, 0.4),       // Ritmo de "gotas"
            \atk, 0.01, \rel, Pwhite(0.3, 0.8), // Envelopes curtos e percussivos
            \freq, Pxrand(~scaleRain, inf) * Pseq([1, 1.5, 2], inf), // Oitavas acima
            \modRatio, Pseq([1, 2, 3.5], inf), // Ratios mais brilhantes
            \modIndex, Pseg([1.0, 3.0], [45], \exp), // Índice crescendo
            \shape, Pwhite(0.1, 0.3),
            \noiseAmt, 0.0,
            \amp, Pwhite(0.06, 0.1),
            \azim, Pwhite(-0.9, 0.9),     // Estéreo total
            \dist, Pwhite(0.1, 0.5),      // Mais perto
            \elev, Pwhite(0.2, 0.8),      // "Caindo" de cima
            \panNoise, 0.3
        )),

        // Transição Rápida (Swell)
        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- Swell ---".postln })),
        Pfindur(5, Pbind(
            \instrument, \fmPseudo3D_cloud_v2,
            \dur, 0.05,
            \atk, 0.5, \rel, 2.0,
            \freq, ~scaleStorm[0] * 2,
            \modRatio, 0.5,
            \modIndex, 5,
            \amp, 0.05,
            \dist, 0.9
        )),

        // ============================================================
        // III. CLÍMAX: TEMPESTADE ESPECTRAL (1:35 - 2:20)
        // ============================================================
        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- III. Climax: Storm ---".postln })),
        Pfindur(45, Pbind(
            \instrument, \fmPseudo3D_cloud_v2,
            \dur, Pbrown(0.02, 0.08, 0.01), // Granular denso
            \atk, 0.005, \rel, 0.15,
            \freq, Pxrand(~scaleStorm, inf) * Pseq([0.5, 1, 2, 4], inf), // Dissonante
            \modRatio, Pseq([1.414, 2.718, 0.5], inf), // Irracionais (sinos/metal)
            \modIndex, Pwhite(4.0, 10.0), // FM Agressiva
            \shape, Pseg([0.4, 0.9, 0.4], [20, 25], \lin), // Waveshaping (distorção)
            \noiseAmt, Pwhite(0.2, 0.5),  // Muita textura de ruído
            \amp, 0.05,
            \azim, Pwhite(-1.0, 1.0),     // 3D Caótico
            \dist, Pseg([0.5, 0.1, 0.8], [15, 30], \exp), // Movimento Z rápido
            \elev, Pwhite(-1.0, 1.0),
            \panNoise, 0.8
        )),

        // ============================================================
        // IV. CODA: O APÓS (2:20 - 3:00)
        // ============================================================
        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- IV. Coda: Aftermath ---".postln })),
        Pfindur(40, Pbind(
            \instrument, \fmPseudo3D_cloud_v2,
            \dur, Pseq([1, 2, 3, 5, 8], inf) * 0.5, // Desacelerando (Fibonacci)
            \atk, 2.0, \rel, 6.0,
            \freq, Pseq([~scaleCoda[0], ~scaleCoda[2], ~scaleCoda[1]], inf),
            \modRatio, 1.001,             // Detune leve (chorus natural)
            \modIndex, 1.5,
            \shape, 0,
            \noiseAmt, 0.02,
            \amp, Pgeom(0.12, 0.9, inf),  // Fade out longo
            \dist, 0.8,
            \room, 0.9,                   // Muito reverb (catedral)
            \azim, Pwhite(-0.5, 0.5)
        )),

        Pbind(\dur, Pseq([0.1], 1), \type, \rest, \log, Pfunc({ "--- Fim da Étude 5 ---".postln }))
    ]).play;

});

// Para parar a execução antes do fim:

~etude5.stop;
