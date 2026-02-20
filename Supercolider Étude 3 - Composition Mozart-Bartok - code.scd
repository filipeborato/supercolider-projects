// ============================================================
// SUPERCOLIDER ÉTUDE 3 - MOZART-BARTÓK
// Morfismo Timbral: FM -> Glockenspiel -> Tuba
// Composição: Mozart (clareza, simetria) + Bartók (assimetria, cromatismo)
// ============================================================

s.options.device = "ASIO : Focusrite USB ASIO";
s.reboot;

// ============================================================
// SYNTHDEF COM TIMBRE MORPHING E ENVELOPE ADSR
// ============================================================

(
SynthDef(\fmPseudo3D_music, {
    |out=0,
     carrierFreq=180, modFreq=90, modIndex=3,
     amp=0.18,
     chaos=0.35,
     width=0.9,
     room=0.35, damp=0.6,
     gate=1,
     timbre=0.0,      // 0=FM básico, 0.5=Glockenspiel, 1=Tuba
     attackTime=0.05  // Attack time para eliminar pops
    |

    var mod, car, sig, noiseSig;
    var azim, elev, front;
    var itd, left, right, ild;
    var upAmt, downAmt, notchHz;
    var env, ampEnv, filterEnv;
    var glockAmount, tubaAmount, fmAmount;
    var glockMod, glockCar, tubaMod1, tubaMod2, tubaCar, breathNoise;
    var bAmt, fAmt;
    
    // Envelope com attack para eliminar pop + diferentes curvas por timbre
    ampEnv = EnvGen.kr(
        Env.adsr(
            attackTime,                    // attack
            0.3 + (timbre * 0.5),         // decay (mais longo para tuba)
            0.7 - (timbre * 0.2),         // sustain (menor para glockenspiel)
            4.0 - (timbre * 2.0)          // release (mais curto para percussivo)
        ),
        gate,
        doneAction: 2
    );
    
    // Envelope de filtro separado para articulação
    filterEnv = EnvGen.kr(
        Env.adsr(
            0.01,                          // attack rápido
            0.1 + (timbre.linlin(0, 0.5, 0, 0.8)),  // decay variável
            0.3,
            1.0
        ),
        gate
    );

    env = ampEnv; // Compatibilidade com código existente

    // Suavização de parâmetros para eliminar clicks de execução
    carrierFreq = carrierFreq.lag(0.08);
    modFreq = modFreq.lag(0.08);
    modIndex = modIndex.lag(0.08);

    azim  = LFDNoise3.kr(chaos);
    elev  = LFDNoise3.kr(chaos * 0.7);
    front = LFDNoise3.kr(chaos * 0.5);

    // Cálculo de quantidades de cada timbre
    // timbre: 0->0.5 = FM -> Glockenspiel
    // timbre: 0.5->1 = Glockenspiel -> Tuba
    glockAmount = (timbre * 2).min(1) * (1 - ((timbre - 0.5).max(0) * 2));
    tubaAmount = ((timbre - 0.5).max(0) * 2);
    fmAmount = 1 - (glockAmount + tubaAmount);
    
    // ========== SÍNTESE FM (Básico) ==========
    mod = SinOsc.ar(modFreq, 0, modIndex * modFreq);
    car = SinOsc.ar(carrierFreq + mod);
    
    // ========== GLOCKENSPIEL (Percussivo, brilhante) ==========
    // Componente metálico com harmônicos inarmônicos
    glockMod = SinOsc.ar(modFreq * 3.76, 0, modIndex * modFreq * 2.1); // ratio inarmônico
    glockCar = SinOsc.ar(carrierFreq * 2 + glockMod) * 0.6;
    glockCar = glockCar + (SinOsc.ar(carrierFreq * 4.2) * 0.3 * filterEnv); // parcial alto
    glockCar = glockCar + (SinOsc.ar(carrierFreq * 6.8) * 0.15 * filterEnv); // brilho
    // Ataque percussivo com ruído
    noiseSig = BPF.ar(WhiteNoise.ar(0.3), carrierFreq * 8, 0.3) * filterEnv * filterEnv;
    glockCar = glockCar + noiseSig;
    
    // ========== TUBA (Grave, escuro, rico) ==========
    // FM com mais moduladores para riqueza
    // Segurança: escala modIndex para evitar dips agressivos em graves
    tubaMod1 = SinOsc.ar(modFreq * 0.5, 0, modIndex * modFreq * 1.5);
    tubaMod2 = SinOsc.ar(modFreq, tubaMod1, modIndex * modFreq);
    tubaCar = SinOsc.ar(carrierFreq + tubaMod2 * (carrierFreq.linlin(40, 400, 0.5, 1.0).clip(0.4, 1.0)));
    // Adiciona sub-harmônicos para corpo grave
    tubaCar = tubaCar + (SinOsc.ar(carrierFreq * 0.5) * 0.4);
    tubaCar = tubaCar + (SinOsc.ar(carrierFreq * 1.5) * 0.25);
    // Componente de "respiração" sutil
    breathNoise = LPF.ar(PinkNoise.ar(0.08), 800) * ampEnv.squared;
    tubaCar = tubaCar + breathNoise;
    
    // ========== MISTURA DE TIMBRES ==========
    car = (car * fmAmount) + (glockCar * glockAmount) + (tubaCar * tubaAmount);

    itd = azim * 0.0006;
    left  = DelayC.ar(car, 0.01, itd.max(0));
    right = DelayC.ar(car, 0.01, itd.neg.max(0));

    ild = (azim * width).clip(-1, 1);
    left  = left  * (1 - ild);
    right = right * (1 + ild);

    sig = [left, right];

    // Suavização das variáveis de profundidade para evitar saltos nos filtros
    bAmt = front.linlin(-1, 1, 1, 0).clip(0, 1).lag(0.2);
    fAmt = 1 - bAmt;

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
// COMPOSIÇÃO MOZART-BARTÓK
// Execute o SynthDef acima primeiro, depois execute este bloco
// ============================================================

(
x = Synth(\fmPseudo3D_music, [
    \amp, 0.10, \carrierFreq, 146, \modFreq, 73, \modIndex, 1.2,
    \chaos, 0.06, \width, 0.8, \room, 0.55, \damp, 0.7,
    \timbre, 0.0, \attackTime, 0.05  // Começa com FM, attack suave
]);

// Centros tonais estilo Mozart (diatônicos) e Bartók (modais/cromáticos)
~mozartCenters = [146.83, 164.81, 185, 196, 220, 246.94]; // D, E, F#, G, A, B (Ré maior)
~bartokCenters = [110, 123.47, 130.81, 146.83, 155.56, 174.61]; // A, B, C, D, Eb, F (frígio)

~pickFrom = { |array| array.choose };

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
    var c, c2;
    
    // ============================================================
    // MOVIMENTO 1: Estilo MOZART
    // Clareza melódica, frases simétricas, harmonia funcional
    // Timbre: FM puro (0.0)
    // ============================================================
    "=== Movimento Mozart ===".postln;
    c = ~pickFrom.(~mozartCenters);
    
    16.do { |i|
        // Frases de 4+4 compassos (simetria mozartiana)
        var phrase = (i % 8 < 4);
        x.set(
            \carrierFreq, ~drift.(c, if(phrase, 15, 25)),
            \modFreq,     ~drift.(c*0.5, 20).clip(30, 180),
            \modIndex,    exprand(0.8, 1.8),
            \chaos,       exprand(0.02, 0.06),
            \room,        exprand(0.60, 0.75),
            \width,       exprand(0.6, 0.85),
            \amp,         exprand(0.07, 0.12),
            \timbre,      0.0,                // FM puro
            \attackTime,  0.05
        );
        (exprand(0.6, 1.0)).wait;
        
        // Mudança de centro tonal a cada 4 notas (cadências)
        if (i % 4 == 3) { c = ~pickFrom.(~mozartCenters); };
    };
    
    // ============================================================
    // TRANSIÇÃO: FM -> GLOCKENSPIEL
    // ============================================================
    "=== Transição -> Glockenspiel ===".postln;
    8.do {
        ~glideSteps.(exprand(0.8, 1.5), 20, { |t|
            x.set(
                \timbre, t * 0.5,  // 0 -> 0.5 (FM -> Glockenspiel)
                \carrierFreq, ~drift.(c, 30),
                \modFreq, exprand(80, 250),
                \modIndex, exprand(1.5, 3.5),
                \chaos, exprand(0.05, 0.15)
            );
        });
        c = ~pickFrom.(~mozartCenters.blend(~bartokCenters, 0.5));
        (exprand(0.3, 0.7)).wait;
    };
    
    // ============================================================
    // MOVIMENTO 2: Estilo BARTÓK
    // Ritmos assimétricos, cromatismo, elementos folclóricos
    // Timbre: Glockenspiel (0.5) -> Tuba (1.0)
    // ============================================================
    "=== Movimento Bartók ===".postln;
    c = ~pickFrom.(~bartokCenters);
    
    24.do { |i|
        // Ritmos assimétricos (padrões 3+2+3, 2+3+2, etc.)
        var rhythmPattern = [0.35, 0.25, 0.4, 0.3, 0.5].choose;
        var timbralShift = i / 24;
        
        x.set(
            \carrierFreq, ~drift.(c, 50),
            \modFreq,     ~drift.(c*[0.66, 0.75, 1.25].choose, 70).clip(25, 380),
            \modIndex,    exprand(2.0, 6.5),
            \chaos,       exprand(0.15, 0.45),
            \room,        exprand(0.20, 0.50),
            \width,       exprand(0.7, 1.0),
            \amp,         exprand(0.09, 0.19),
            \timbre,      0.5 + (timbralShift * 0.5),  // Glock -> Tuba
            \attackTime,  exprand(0.02, 0.08)
        );
        rhythmPattern.wait;
        
        // Mudanças tonais cromáticas irregulares
        if ([true, false, false].choose) {
            c = ~pickFrom.(~bartokCenters);
        };
    };
    
    // ============================================================
    // MOVIMENTO 3: Síntese MOZART-BARTÓK
    // Mistura: clareza mozartiana com tuba grave
    // ============================================================
    "=== Síntese Final ===".postln;
    c = ~pickFrom.(~mozartCenters);
    
    12.do {
        c2 = ~pickFrom.(~bartokCenters);
        ~glideSteps.(exprand(1.5, 3.0), 35, { |t|
            x.set(
                \carrierFreq, ~drift.(c.blend(c2, t), 40),
                \modFreq,     exprand(35, 320),
                \modIndex,    exprand(1.5, 5.0),
                \chaos,       exprand(0.10, 0.35),
                \room,        exprand(0.30, 0.60),
                \width,       exprand(0.65, 0.95),
                \amp,         exprand(0.08, 0.16),
                \timbre,      0.85 + (t * 0.15),  // Predominantemente tuba
                \attackTime,  0.08
            );
        });
        c = c2;
        (exprand(0.2, 0.5)).wait;
    };
    
    // ============================================================
    // CODA: Retorno ao Mozart com Tuba
    // ============================================================
    "=== Coda ===".postln;
    c = ~mozartCenters[0]; // Tônica
    
    10.do { |i|
        x.set(
            \carrierFreq, ~drift.(c, 12),
            \modFreq,     ~drift.(c*0.5, 15).clip(30, 150),
            \modIndex,    exprand(0.5, 1.5),
            \chaos,       exprand(0.02, 0.08),
            \room,        exprand(0.65, 0.85),
            \width,       exprand(0.5, 0.8),
            \amp,         exprand(0.04, 0.09) * (1 - (i/10)),  // diminuendo
            \timbre,      1.0,                                  // Tuba plena
            \attackTime,  0.12 + (i * 0.02)
        );
        (exprand(0.8, 1.8)).wait;
    };

    x.set(\gate, 0);
    "=== Fim ===".postln;
}).play;
)

// Para parar: r.stop; x.set(\gate, 0);
