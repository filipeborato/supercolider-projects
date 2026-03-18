# SuperCollider Études

Este projeto contém uma coleção de estudos e composições eletroacústicas experimentais desenvolvidas na linguagem **SuperCollider**. Os estudos (Études) elaborados exploram profundamente técnicas avançadas de síntese sonora, espacialização pseudo-3D e abordagens de composição algorítmica e generativa.

## 🎵 Estrutura das Obras e Estudos

O projeto é dividido em 6 *Études* principais:

### 1 & 2. Étude 1 e 2 - FM and Space
Estudos iniciais com foco na exploração da síntese **FM (Modulação em Frequência)** combinada com técnicas de espacialização detalhadas.
- Buscam criar texturas complexas e brincar com a percepção de distância, elevação e profundidade acústica no campo estéreo.

### 3. Étude 3 - Composition Mozart-Bartók
Uma peça generativa estruturada em torno do **morfismo timbral**, fluindo de um timbre de FM básico para sons semelhantes a um Glockenspiel e, enfim, uma Tuba. Define centros tonais de dois compositores contrastantes:
- **Movimento Mozart:** Foca em clareza melódica, frases simétricas e centros tonais diatônicos puros.
- **Movimento Bartók:** Introduz ritmos assimétricos, cromatismo irregular e escalas de textura modal.

### 4. Étude 4 - Spectral Clouds
Estudo focado em texturas baseadas em espectro e "nuvens" de som. Contém renderizações tanto em WAV lossless quanto MP3 masterizado.

### 5. Étude 5 - Extended Evolution
Uma composição guiada por padrões (`Pbind` / Padrões do SC) dividida em quatro ecossistemas: Nébula (Intro), Chuva Estruturada (Desenvolvimento), Tempestade Espectral (Clímax) e O Após (Coda).
- Utiliza o motor `FM3D_CLOUD_V2`, um motor de síntese granular avançado com manipulação espacial pesada, waveshaping e injeção de ruído.

### 6. Étude 6 - Metamorfoses
Explora a dicotomia e mutação entre densidade e impulsos. Dividido em Zonas (Matéria, Impulsos, Fluxo, Dissolução).
- Usa dois instrumentos principais: `eMass` (para massas sustentadas, longos envelopes linen) e `eVoice` (para impulsos). 
- Técnicas avançadas incluem filtros HPF restritos a 30Hz e faserealização (random phase) em moduladores para evitar cancelamento de fase indesejado entre múltiplos nós simultâneos.

---

## 📁 Sobre os Arquivos do Diretório

- **Códigos-Fonte (`*.scd`)**: Cada arquivo .scd correspondente traz o código da peça. A estrutura em geral é dividida num bloco de `SynthDef` e depois padrões tocadores ou `Routine`.
- **Renderizações (`*.wav`, `*.mp3`)**: Versões de áudio geradas das avaliações do código, servindo de documentação direta do resultado sonoro.
- **Imagens (`*.png`)**: Apoios visuais possivelmente documentando o processo ou análise espectral em certos momentos de execução.
- **Textos Adjuntos (`*.md`)**: Algumas anotações em Markdown paralelas referentes a outros tópicos ou contexto (ex: *Genealogia Cristã.md*).

## 🚀 Como Executar

Para reproduzir os estudos, você precisará ter o [SuperCollider](https://supercollider.github.io/) e um servidor de áudio (sclang/scsynth) funcionando.
Como o repositório indica o uso do VS Code (pasta `.vscode`), você pode rodar as peças com a extensão do SC para o VS Code.

1. Abra um arquivo `.scd`.
2. Certifique-se de estar com o servidor ligado (`s.boot;`). Pode ser necessário ajustar o `s.options.device` inicial caso seu driver de áudio não seja o ASIO padrão listado.
3. Avalie o bloco de **SynthDef** para enviar as definições ao servidor.
4. Avalie o bloco de composição (Geralmente um `Pseq` ou `Routine.play`) para escutar o estudo em andamento.

> **Dica**: Para interromper a execução repentinamente durante o play, utilize as funções locais designadas (ex: `~etude6.stop;` ou atalho padrão de parar o sclang).
