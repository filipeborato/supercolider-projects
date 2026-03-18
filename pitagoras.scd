// ==============================================
// VERSÃO FINAL 100% CORRIGIDA – Sem nenhum "var" atrasado!
// O erro era exatamente isso: você NÃO pode colocar "var" depois de já ter executado código dentro da Routine.
// Agora TODOS os "var" estão no INÍCIO de cada bloco.
// Rode BLOCO por BLOCO (Cmd+Enter)
// ==============================================

s.boot;  // Primeiro isso (se ainda não bootou)

// 1. Synth básico
(
SynthDef(\sine, { |freq=440, amp=0.3, dur=4, pan=0|
    var sig = SinOsc.ar(freq, 0, amp);
    var env = EnvGen.kr(Env.perc(0.02, dur), doneAction:2);
    Out.ar(0, Pan2.ar(sig * env, pan));
}).add;
)

// Função pra tocar
(~play = { |freq, dur=3, amp=0.25, pan=0|
    Synth(\sine, [\freq, freq.asFloat, \dur, dur, \amp, amp, \pan, pan]);
};)

// ==============================================
// BLOCO 2 – Pitágoras (já funcionava)

(
"--- Pitágoras: intervalos puros ---".postln;
~play.(440);
~play.(440 * 2,     3, pan: 0.3);
~play.(440 * 3/2,   3, pan: -0.3);
~play.(440 * 4/3,   3, pan: 0.2);
)


// ==============================================
// BLOCO 3 – Círculo de quintas + Comma (AGORA CORRIGIDO!)
(
Routine({
    // ← TODOS os var aqui em cima, antes de qualquer coisa!
    var base = 261.63;
    var freq = base;
    var comma;
    var diffCents;

    "--- Círculo de quintas pitagórico: o comma aparece! ---".postln;

    12.do { |i|
        freq = freq * (3/2);
        if(i == 11) { comma = freq };
        ~play.(freq, 2, amp:0.22, pan: i.linlin(0,11,-0.9,0.9));
        2.3.yield;
    };

    ~play.(base * 2.pow(7), 4, amp:0.4, pan:0);
    ~play.(comma,           4, amp:0.4, pan:0);

    diffCents = 1200 * log2(comma / (base * 2.pow(7)));
    ("Pythagorean comma: " ++ diffCents.round(2) ++ " cents").postln;
}).play;
)

s.quit;
// ==============================================
// BLOCO 4 – Just vs 12-TET
(
Routine({
    var root = 261.63;

    "--- Just Intonation vs 12-TET: ouça a terça! ---".postln;

    ~play.(root,          6, pan:-0.5);
    ~play.(root * 5/4,    6, pan:0);
    ~play.(root * 3/2,    6, pan:0.5);

    7.yield;

    "--- Agora o mesmo acorde em temperamento igual ---".postln;

    ~play.(root,                  6, pan:-0.5);
    ~play.(root * 2.pow(4/12),    6, pan:0);
    ~play.(root * 2.pow(7/12),    6, pan:0.5);
}).play;
)
)

// ==============================================
// BLOCO 5 – Mesotônico
(
Routine({
    var root = 261.63;
    var mesoFifth = 1.495348781;

    "--- Mesotônico (1/4 comma): terças perfeitas! ---".postln;

    ~play.(root,           5, pan:-0.6);
    ~play.(root * 5/4,     5, pan:0);
    ~play.(root * mesoFifth,5, pan:0.6);

    7.yield;

    "--- Acorde problemático (quinta lobo) ---".postln;

    ~play.(root * 2.pow(6/12),  5, pan:-0.6);
    ~play.(root * 2.pow(10/12), 5, pan:0);
    ~play.(root * 2.pow(1/12) * mesoFifth, 5, pan:0.6);
}).play;
)
)

// ==============================================
// BLOCO 6 – Piano + Violino ajustando
(
Routine({
    var pianoA = 440;

    "--- Piano (TET) + Violino ajustando ---".postln;

    ~play.(pianoA,           8, amp:0.18, pan:-0.4);
    ~play.(pianoA * 2.pow(4/12), 8, amp:0.18, pan:0.4);

    6.yield;

    ~play.(pianoA * (5/4) * 0.995, 6, amp:0.25, pan:0);
}).play;
)
)

