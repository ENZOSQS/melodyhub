# Créditos dos samples de áudio

Os samples de piano e violão usados pelo Melody Hub foram redistribuídos do
repositório [Tone.js Instruments](https://github.com/nbrosowsky/tonejs-instruments),
mantido por [Nicholas Brosowsky](https://github.com/nbrosowsky). O repositório
declara os arquivos de áudio sob a licença [Creative Commons Attribution 3.0
Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/), que permite
redistribuição e adaptação com atribuição adequada.

- **Piano (Salamander Grand Piano):** samples selecionados do pacote piano.
  O instrumento original é de Alexander Holm; fonte indicada pelo projeto:
  [Salamander Grand Piano](https://github.com/nbrosowsky/tonejs-instruments/tree/master/samples/piano).
- **Violão aço (guitar-acoustic):** samples selecionados do pacote acústico,
  cuja fonte indicada é a University of Iowa Electronic Music Studios:
  [Iowa Musical Instrument Samples](https://theremin.music.uiowa.edu/).
- **Violão nylon (guitar-nylon):** notas agudas selecionadas do pacote nylon,
  fonte Freesound, gravação de `quartertone` ID 11573:
  [Freesound 11573](https://freesound.org/s/11573/).
- [Informações de origem dos samples no repositório](https://github.com/nbrosowsky/tonejs-instruments/blob/master/sample-source-info.txt)
- [Licença de áudio declarada pelo repositório](https://github.com/nbrosowsky/tonejs-instruments/blob/master/LICENSE.md)

Os arquivos de código do repositório Tone.js Instruments têm licença MIT; essa
licença não substitui a licença CC BY 3.0 dos samples de áudio. Os arquivos
originais foram mantidos em OGG e usados com atribuição. Para MIDI sem gravação
exata, o app seleciona um sample até um semitom distante e aplica a razão de
afinação correspondente.

## Exercícios auditivos

Os exercícios auditivos (Identificar a nota, Intervalos e Escalas) não usam
samples: o som é sintetizado no próprio aplicativo com o `flutter_soloud`
(licença MIT), somando ondas senoidais e triangulares com envelope de volume.
Assim cada nota sai na afinação exata, sem chiado de gravação. Os samples do
Tone.js Instruments continuam sendo usados apenas nos simuladores de teclado e
de violão e no exercício no braço do violão. Os cliques do exercício de
andamento (BPM) são os arquivos `metronome_beat.wav` e `metronome_downbeat.wav`
do próprio projeto.
