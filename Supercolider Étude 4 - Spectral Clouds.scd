s.options.device = "ASIO : Focusrite USB ASIO";
s.reboot;

(
// ============================================================
// SYNTHDEF: FM3D_CLOUD (Granular/Polifônico)
// Otimizado para "Nuvens" de som. Cada nota é um grão independente.
// ============================================================
SynthDef(\fmPseudo3D_cloud, {
    |out=0,
     freq=110, modRatio=0.5, modIndex=3,
     amp=0.1,
     azim=0,        // -1 (esq) a +1 (dir)
     elev=0,        // -1 (baixo) a +1 (cima)
     dist=0,        // 0 (perto) a 1 (longe)
     atk=0.1, rel=1.5,
     panNoise=0.0   // jitter espacial extra
    |

    var mod, car, sig, env;
    var itd, left, right, ild;
    var bAmt, fAmt, upAmt, downAmt, notchHz;
    var localAzim, room, damp;

    // Envelope Percussivo para Grãos (Self-freeing)
    env = EnvGen.ar(Env.perc(atk, rel, 1, -4), doneAction: 2);

    // Jitter espacial (pequena variação aleatória por grão)
    localAzim = (azim + LFNoise1.kr(10, panNoise)).clip(-1, 1);

    // Síntese FM
    mod = SinOsc.ar(freq * modRatio, 0, modIndex * (freq * modRatio));
    car = SinOsc.ar(freq + mod);

    // Filtro de "Distância" (mais longe = mais abafado)
    car = LPF.ar(car, 18000 / (1 + (dist * 10)));

    // --- Espacialização Pseudo-3D (Binaural Simplificado) ---

    // ITD (Time Difference)
    itd = localAzim * 0.0006;
    left  = DelayC.ar(car, 0.01, itd.max(0));
    right = DelayC.ar(car, 0.01, itd.neg.max(0));

    // ILD (Level Difference)
    ild = (localAzim * 0.8).clip(-1, 1);
    left  = left  * (1 - ild);
    right = right * (1 + ild);
    sig = [left, right];

    // Profundidade (Front/Back -> LowPass filter changes)
    bAmt = dist.clip(0, 1);
    fAmt = 1 - bAmt;

    // Elevação (Up/Down -> Spectral notches)
    upAmt = elev.clip(0, 1);
    downAmt = (1 - upAmt).max(0); // Assumindo elev 0 a 1 para simplificar, ou mapear -1..1

    // Notch para simular HRTF de elevação
    notchHz = (6000 * downAmt + 10000 * upAmt).clip(4000, 12000);
    sig = BPeakEQ.ar(sig, notchHz, 0.7, -8);

    // Reverb integrado (simulando "smearing" da nuvem)
    room = 0.3 + (dist * 0.5); // Mais longe = mais "sala"
    damp = 0.5;
    sig = FreeVerb2.ar(sig[0], sig[1], room * 0.4, room, damp);

    Out.ar(out, sig * amp * env);
}).add;
)

// ============================================================
// COMPOSIÇÃO: "NUVENS ESPECTRAIS" (Granular Pattern)
// Execute este bloco para tocar a peça inteira.
// ============================================================
(
var centers = [110, 130.81, 146.83, 164.81, 196, 220]; // Pentatônica/Modal A

Pseq([
    // --- FASE 1: GÊNESE (Surgimento das Nuvens) ---
    // Grãos longos, esparsos, graves.
    Pbind(
        \instrument, \fmPseudo3D_cloud,
        \dur, Pwhite(0.5, 2.0),      // Ritmo lento/irregular
        \atk, 1.0, \rel, 3.0,        // Envelopes longos (drones)
        \freq, Pxrand(centers * 0.5, 12),
        \modRatio, 0.5,
        \modIndex, Pwhite(0.5, 1.5),
        \amp, Pwhite(0.1, 0.15),
        \azim, Pwhite(-0.3, 0.3),    // Centro da imagem estéreo
        \dist, Pwhite(0.6, 0.9),     // Longe
        \panNoise, 0.1
    ),

    // --- FASE 2: EXPANSÃO (Crescendo a Textura) ---
    // Aumenta densidade, "abre" o estéreo.
    Pbind(
        \instrument, \fmPseudo3D_cloud,
        \dur, Pwhite(0.1, 0.3),      // Ritmo mais rápido (grãos)
        \atk, 0.05, \rel, Pwhite(0.5, 1.2),
        \freq, Pxrand(centers, 40),
        \modRatio, Prand([0.5, 1.0, 1.5], inf),
        \modIndex, Pexprand(1.0, 4.0),
        \amp, Pwhite(0.08, 0.12),
        \azim, Pwhite(-0.8, 0.8),    // Imagem mais larga
        \elev, Pwhite(-0.5, 0.5),    // Alguma elevação
        \dist, Pseg([0.8, 0.2], [10], \exp), // Aproximando
        \panNoise, 0.2
    ),

    // --- FASE 3: ENXAME (Caos Granular) ---
    // Alta densidade, espacialização extrema, FM agressiva.
    Pbind(
        \instrument, \fmPseudo3D_cloud,
        \dur, Pbrown(0.02, 0.08, 0.01), // Super rápido (textura)
        \atk, 0.005, \rel, 0.1,
        \freq, Pxrand(centers * 2, 80), // 80 eventos
        \modRatio, Pseq([2.23, 3.5, 1.4], inf), // Inarmônico
        \modIndex, Pwhite(3.0, 8.0),
        \amp, 0.06,
        \azim, Pwhite(-1.0, 1.0),
        \elev, Pwhite(-1.0, 1.0), // Teto e chão
        \dist, Pwhite(0.0, 0.4),  // Perto ("na cara")
        \panNoise, 0.5
    ),

    // --- FASE 4: DISSIPAÇÃO (Ecos Distantes) ---
    Pbind(
        \instrument, \fmPseudo3D_cloud,
        \dur, Pseq([0.5, 1.0, 1.5, 2.0, 3.0], 1), // Desacelerando
        \atk, 1.0, \rel, 4.0,
        \freq, Pseq([centers[0], centers[2], centers[0]*0.5], inf),
        \modRatio, 0.5,
        \modIndex, 0.5,
        \amp, Pgeom(0.1, 0.6, 5), // Fade out
        \dist, 0.9,
        \room, 0.8
    )
]).play;
)

r.stop; x.set(\gate, 0);