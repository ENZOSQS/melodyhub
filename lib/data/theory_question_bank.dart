typedef TheoryLearningNote = ({String hint, String explanation});

const theoryLearningNotes = <String, TheoryLearningNote>{
  'bas_01': (
    hint:
        'Conte apenas as notas sem sustenido ou bemol; não conte as teclas pretas.',
    explanation:
        'A sequência natural tem sete nomes: Dó, Ré, Mi, Fá, Sol, Lá e Si. As alterações criam outras alturas, mas não novos nomes naturais.',
  ),
  'bas_02': (
    hint: 'Recite a sequência natural na ordem, sem pular nomes.',
    explanation:
        'Na ordem Dó, Ré, Mi, Fá, Sol, Lá, Si, Fá vem imediatamente depois de Mi.',
  ),
  'bas_03': (
    hint: 'Pense no nome natural que aparece logo antes de Sol.',
    explanation:
        'A sequência natural ascendente passa por Fá antes de chegar a Sol.',
  ),
  'bas_04': (
    hint: 'A escala natural começa em Dó e alterna os nomes até Si.',
    explanation:
        'A ordem das sete notas naturais é Dó, Ré, Mi, Fá, Sol, Lá e Si; depois dela, a sequência recomeça em Dó na oitava seguinte.',
  ),
  'bas_05': (
    hint:
        'Lembre-se do símbolo que costuma marcar a região mais aguda da pauta.',
    explanation:
        'A clave de sol marca a nota Sol na segunda linha da pauta e é muito usada para registros agudos, inclusive na mão direita do piano.',
  ),
  'bas_06': (
    hint: 'Pense na clave que marca a nota Fá na quarta linha da pauta.',
    explanation:
        'A clave de fá marca Fá na quarta linha e é comum para registros graves e para a mão esquerda do piano.',
  ),
  'bas_07': (
    hint:
        'Na escala natural, procure as duas passagens sem tecla preta entre notas vizinhas.',
    explanation:
        'Mi–Fá e Si–Dó são semitons naturais. Entre as outras notas naturais vizinhas há um tom.',
  ),
  'bas_08': (
    hint:
        'No 4/4, o número de cima indica quantas unidades de semínima cabem no compasso.',
    explanation:
        'Em 4/4 há quatro tempos de semínima por compasso; o 4 de baixo indica a semínima como unidade de referência.',
  ),
  'bas_09': (
    hint: 'Use a contagem comum “1, 2, 3, 4” de um compasso simples.',
    explanation:
        'Na contagem usual do compasso 4/4, cada semínima ocupa um tempo.',
  ),
  'bas_10': (
    hint: 'Uma pausa afeta o som e também tem uma duração escrita.',
    explanation:
        'A pausa é um símbolo de silêncio com duração definida; ela não representa uma nota mais aguda nem uma mudança de instrumento.',
  ),
  'bas_11': (
    hint: 'Pense no elemento que organiza a música ao longo do tempo.',
    explanation:
        'O ritmo organiza a duração e a sequência de sons e silêncios.',
  ),
  'bas_12': (
    hint: 'Compare a frequência do som, não seu volume ou quanto ele dura.',
    explanation:
        'A altura distingue sons graves e agudos e está relacionada à frequência: frequências menores soam mais graves.',
  ),
  'bas_13': (
    hint:
        'Entre Dó e Ré existe uma tecla preta; cada tecla vizinha representa um semitom.',
    explanation:
        'Dó–Dó sustenido é um semitom e Dó sustenido–Ré é outro; por isso, Dó e Ré ficam a dois semitons de distância.',
  ),
  'bas_14': (
    hint: 'A tônica dá nome à escala maior.',
    explanation:
        'A escala de Dó maior começa na tônica Dó e segue Dó, Ré, Mi, Fá, Sol, Lá e Si.',
  ),
  'bas_15': (
    hint:
        'Imagine dois instrumentos tocando a mesma nota e com o mesmo volume.',
    explanation:
        'O timbre é a característica que ajuda a distinguir fontes sonoras diferentes mesmo quando tocam a mesma altura.',
  ),
  'int_01': (
    hint: 'A escala maior tem semitons entre os graus 3–4 e 7–8.',
    explanation:
        'A fórmula da escala maior é tom, tom, semitom, tom, tom, tom, semitom (T–T–ST–T–T–T–ST).',
  ),
  'int_02': (
    hint: 'Dó maior é a tonalidade de referência sem sustenidos nem bemóis.',
    explanation:
        'A armadura de Dó maior não tem alterações; por isso, sua escala usa apenas as notas naturais.',
  ),
  'int_03': (
    hint: 'A ordem dos sustenidos começa por Fá.',
    explanation: 'Sol maior tem um sustenido na armadura: Fá sustenido.',
  ),
  'int_04': (
    hint: 'A ordem dos bemóis começa por Si.',
    explanation: 'Fá maior tem um bemol na armadura: Si bemol.',
  ),
  'int_05': (
    hint:
        'A armadura de Ré maior tem dois sustenidos; consulte a ordem padrão deles.',
    explanation:
        'Ré maior tem Fá sustenido e Dó sustenido, os dois primeiros sustenidos da ordem Fá–Dó–Sol–Ré–Lá–Mi–Si.',
  ),
  'int_06': (
    hint: 'Conte os semitons de uma nota até a mesma nota na oitava seguinte.',
    explanation: 'No sistema temperado, uma oitava contém doze semitons.',
  ),
  'int_07': (
    hint:
        'Uma quinta justa equivale a sete teclas vizinhas contando os semitons entre as notas.',
    explanation:
        'A quinta justa corresponde a sete semitons no sistema temperado.',
  ),
  'int_08': (
    hint:
        'Uma tríade usa a fundamental, uma terça e uma quinta; a terça maior define sua qualidade.',
    explanation:
        'Na escala maior, uma tríade maior usa os graus 1, 3 e 5: fundamental, terça maior e quinta justa.',
  ),
  'int_09': (
    hint:
        'Compare a distância da fundamental até a terça em acordes maiores e menores.',
    explanation:
        'A terça menor fica a três semitons da fundamental e dá à tríade menor sua qualidade característica.',
  ),
  'int_10': (
    hint:
        'A relativa menor compartilha a armadura e começa no sexto grau da escala maior.',
    explanation:
        'Lá menor é a relativa de Dó maior: ambas usam as mesmas notas naturais, mas têm tônicas diferentes.',
  ),
  'int_11': (
    hint:
        'O número de cima da fórmula 3/4 informa quantos tempos há no compasso.',
    explanation:
        'Em 3/4, cada compasso reúne três tempos, normalmente contados em semínimas.',
  ),
  'int_12': (
    hint:
        'O símbolo de semínima indica qual valor rítmico está sendo marcado por minuto.',
    explanation:
        'A indicação ♩ = 120 significa 120 semínimas, ou batidas, por minuto.',
  ),
  'int_13': (
    hint:
        'No teclado, pense no movimento para a tecla imediatamente à direita.',
    explanation: 'Um sustenido eleva a nota escrita em um semitom.',
  ),
  'int_14': (
    hint:
        'No teclado, pense no movimento para a tecla imediatamente à esquerda.',
    explanation: 'Um bemol abaixa a nota escrita em um semitom.',
  ),
  'int_15': (
    hint: 'Na síncope, a acentuação não coincide com o pulso forte esperado.',
    explanation:
        'A síncope desloca a ênfase para uma parte fraca do tempo ou do compasso, criando sensação de deslocamento rítmico.',
  ),
  'ava_01': (
    hint:
        'Compare a escala menor harmônica com a menor natural no sétimo grau.',
    explanation:
        'A menor harmônica eleva o sétimo grau da menor natural para criar uma sensível e reforçar a atração pela tônica.',
  ),
  'ava_02': (
    hint:
        'Na forma tradicional, a menor melódica muda ao subir; pense nos graus próximos à tônica.',
    explanation:
        'Na menor melódica tradicional ascendente, os graus 6 e 7 são elevados em relação à menor natural; na descida, costuma-se usar a forma natural.',
  ),
  'ava_03': (
    hint: 'O trítono divide a oitava em duas partes iguais.',
    explanation:
        'O trítono mede seis semitons, metade dos doze semitons da oitava.',
  ),
  'ava_04': (
    hint:
        'O acorde dominante com sétima combina uma tríade maior com uma sétima menor.',
    explanation:
        'A tétrade dominante é formada por 1, 3, 5 e ♭7: fundamental, terça maior, quinta justa e sétima menor.',
  ),
  'ava_05': (
    hint: 'Observe qual nota do acorde está na posição mais grave.',
    explanation:
        'Uma inversão acontece quando uma nota diferente da fundamental fica no baixo; a qualidade do acorde continua a mesma.',
  ),
  'ava_06': (
    hint:
        'Use a frase mnemônica em que cada novo sustenido sobe uma quinta em relação ao anterior.',
    explanation:
        'A ordem convencional dos sustenidos é Fá, Dó, Sol, Ré, Lá, Mi e Si.',
  ),
  'ava_07': (
    hint:
        'Dó sustenido maior fica no extremo das tonalidades com sustenidos da escala maior.',
    explanation:
        'Dó sustenido maior tem sete sustenidos: Fá, Dó, Sol, Ré, Lá, Mi e Si.',
  ),
  'ava_08': (
    hint: 'Em 6/8, conte seis colcheias agrupadas em dois conjuntos de três.',
    explanation:
        'O compasso composto 6/8 costuma ser sentido em dois tempos principais, cada um subdividido em três colcheias.',
  ),
  'ava_09': (
    hint: 'Uma cadência autêntica caminha da função dominante para a tônica.',
    explanation:
        'A cadência autêntica é o movimento V–I, que conduz da dominante ao acorde de tônica.',
  ),
  'ava_10': (
    hint: 'Em Dó maior, Sol é o quinto grau e contém a sensível Si.',
    explanation:
        'O acorde de Sol maior é o V grau de Dó maior e exerce função dominante, criando expectativa de resolução em Dó.',
  ),
  'ava_11': (
    hint: 'Comece em Ré e use somente teclas brancas até o próximo Ré.',
    explanation:
        'Ré–Mi–Fá–Sol–Lá–Si–Dó–Ré tem a fórmula de tons e semitons do modo dórico.',
  ),
  'ava_12': (
    hint: 'O modo tem uma quarta um semitom acima da quarta justa.',
    explanation:
        'O modo lídio se distingue pelo quarto grau elevado (quarta aumentada) em relação à tônica.',
  ),
  'ava_13': (
    hint:
        'Pense em duas grafias diferentes para a mesma tecla no teclado temperado.',
    explanation:
        'Notas enarmônicas têm nomes e grafias diferentes, mas soam na mesma altura no sistema temperado, como Fá sustenido e Sol bemol.',
  ),
  'ava_14': (
    hint:
        'Imagine tocar a mesma melodia começando em outra nota, mantendo seus contornos.',
    explanation:
        'Transpor muda as alturas absolutas, mas mantém as distâncias entre as notas para preservar a identidade intervalar da melodia.',
  ),
  'ava_15': (
    hint: 'A sensível é o grau que fica imediatamente abaixo da tônica.',
    explanation:
        'Na escala maior, o sétimo grau está a um semitom da tônica e tende a resolver nela.',
  ),
  'av2_01': (
    hint:
        'Monte os acordes da escala de Dó maior usando apenas notas da tonalidade.',
    explanation:
        'O acorde sobre o segundo grau de Dó maior usa Ré–Fá–Lá, formando Ré menor, representado por ii.',
  ),
  'av2_02': (
    hint:
        'A cadência plagal costuma ser chamada de “amém” e termina na tônica.',
    explanation:
        'Em Dó maior, Fá é o acorde IV e Dó é o I; o movimento IV–I caracteriza a cadência plagal.',
  ),
  'av2_03': (
    hint:
        'A tríade diminuta diatônica sobre o sétimo grau usa terças empilhadas dentro de Dó maior.',
    explanation:
        'Sobre Si em Dó maior, as notas Si–Ré–Fá formam uma terça menor e uma quinta diminuta, características da tríade diminuta.',
  ),
  'av2_04': (
    hint:
        'Na fórmula 6/8, o número de cima conta as unidades indicadas pelo 8.',
    explanation:
        'O 6/8 contém seis colcheias por compasso, normalmente agrupadas como dois tempos compostos de três colcheias.',
  ),
  'av2_05': (
    hint: 'Na primeira inversão, a terça do acorde fica no baixo.',
    explanation:
        'A tríade de Dó maior tem Dó–Mi–Sol. Na primeira inversão, Mi é a nota mais grave.',
  ),
  'av2_06': (
    hint:
        'Sol7 é um acorde de quatro notas; a sétima fica um tom abaixo da oitava.',
    explanation:
        'Sol7 contém fundamental Sol, terça maior Si, quinta justa Ré e sétima menor Fá.',
  ),
  'av2_07': (
    hint:
        'Antes da dominante, muitas progressões usam a função que cria movimento para longe da tônica.',
    explanation:
        'A função subdominante, também chamada predominante em muitos contextos, prepara com frequência a dominante.',
  ),
  'av2_08': (
    hint:
        'A armadura vale para a tonalidade e afeta certas notas ao longo da peça.',
    explanation:
        'A armadura de clave indica quais notas são alteradas de forma recorrente pela tonalidade, evitando repetir esses sinais em cada ocorrência.',
  ),
  'av2_09': (
    hint:
        'Compare as três notas com a tríade maior de Lá: a terça é que muda sua qualidade.',
    explanation:
        'Lá–Dó–Mi reúne fundamental, terça menor e quinta justa, formando a tríade de Lá menor.',
  ),
  'av2_10': (
    hint: 'A ordem dos bemóis é Si, Mi, Lá, Ré, Sol, Dó, Fá.',
    explanation: 'Mi bemol maior tem três bemóis na armadura: Si, Mi e Lá.',
  ),
  'esp_01': (
    hint:
        'A sétima da dominante tende a resolver no acorde cuja tônica está uma quarta acima.',
    explanation:
        'Em Dó maior, Sol7 é V7 e resolve com frequência em Dó maior (I), movimento V7–I.',
  ),
  'esp_02': (
    hint: 'A menor harmônica eleva o sétimo grau da escala natural.',
    explanation:
        'Em Lá menor harmônica, o sétimo grau Sol é elevado para Sol sustenido, a sensível que conduz a Lá.',
  ),
  'esp_03': (
    hint:
        'O modo frígio começa como uma escala menor com uma alteração característica no segundo grau.',
    explanation:
        'O segundo grau menor, a um semitom da tônica, é a característica mais reconhecível do modo frígio.',
  ),
  'esp_04': (
    hint:
        'Considere como duas linhas melódicas independentes soam quando avançam em quintas paralelas.',
    explanation:
        'Na prática tradicional de contraponto, quintas paralelas podem fazer as vozes soarem fundidas, reduzindo a independência entre as linhas.',
  ),
  'esp_05': (
    hint:
        'Comece com uma tríade menor e abaixe a quinta; depois acrescente uma sétima menor.',
    explanation:
        'A tétrade meio-diminuta tem fundamental, terça menor, quinta diminuta e sétima menor: 1–♭3–♭5–♭7.',
  ),
  'esp_06': (
    hint:
        'A dominante secundária de Ré é o acorde construído uma quinta justa acima de Ré.',
    explanation:
        'Lá maior ou Lá7 contém Dó sustenido, que conduz a Ré; por isso, funciona como V/ii em Dó maior.',
  ),
  'esp_07': (
    hint:
        'Leia as letras da forma como seções musicais: A, depois B, depois A novamente.',
    explanation:
        'Na forma ABA, a seção final retoma o material temático da seção A, às vezes com variações.',
  ),
  'esp_08': (
    hint:
        'Um intervalo composto ultrapassa uma oitava; retire uma oitava para achar o intervalo simples correspondente.',
    explanation:
        'Uma nona maior equivale a uma oitava justa mais uma segunda maior, totalizando 14 semitons.',
  ),
  'esp_09': (
    hint:
        'Compare a terça maior e a sétima menor do acorde dominante com os modos diatônicos.',
    explanation:
        'O modo mixolídio tem fórmula 1–2–3–4–5–6–♭7, que combina com a tríade maior e a sétima menor de um acorde dominante.',
  ),
  'esp_10': (
    hint:
        'Na cadência deceptiva, a dominante evita o acorde esperado de tônica.',
    explanation:
        'Em tonalidade maior, V–vi é deceptiva porque a dominante resolve no sexto grau em vez de chegar ao I.',
  ),
};

class TheoryQuestion {
  const TheoryQuestion({
    required this.id,
    required this.category,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.difficulty,
  });

  final String id;
  final String category;
  final String prompt;
  final List<String> options;
  final String answer;
  final int difficulty;

  String get hint =>
      theoryLearningNotes[id]?.hint ??
      'Lembre-se do conceito de $category e tente relacioná-lo ao enunciado.';

  String get explanation =>
      theoryLearningNotes[id]?.explanation ??
      'A resposta correta é $answer. Revise o conceito de $category para reconhecer esse padrão em outros exercícios.';
}

/// Banco local para ampliar e revisar questões sem acoplar conteúdo à tela.
/// Dificuldades: 1 iniciante, 2 intermediário, 3 avançado, 4 avançado II e 5 especialista.
const theoryQuestionBank = <TheoryQuestion>[
  // Iniciante
  TheoryQuestion(
    id: 'bas_01',
    category: 'Notas',
    prompt: 'Quantas notas naturais existem na música ocidental?',
    options: ['5', '6', '7', '8'],
    answer: '7',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_02',
    category: 'Notas',
    prompt:
        'Na sequência ascendente das sete notas naturais, qual nota vem depois de Mi?',
    options: ['Ré', 'Fá', 'Sol', 'Lá'],
    answer: 'Fá',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_03',
    category: 'Notas',
    prompt:
        'Na sequência ascendente das sete notas naturais, qual nota vem antes de Sol?',
    options: ['Mi', 'Fá', 'Lá', 'Si'],
    answer: 'Fá',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_04',
    category: 'Notas',
    prompt: 'Qual é a sequência natural ascendente correta?',
    options: [
      'Dó, Ré, Mi, Fá, Sol, Lá, Si',
      'Dó, Mi, Ré, Fá, Sol, Si, Lá',
      'Ré, Dó, Mi, Sol, Fá, Lá, Si',
      'Dó, Ré, Fá, Mi, Lá, Sol, Si',
    ],
    answer: 'Dó, Ré, Mi, Fá, Sol, Lá, Si',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_05',
    category: 'Partitura',
    prompt:
        'Qual clave é mais usada para notas agudas e para a mão direita do piano?',
    options: [
      'Clave de fá',
      'Clave de sol',
      'Clave de dó na quarta linha',
      'Clave de percussão',
    ],
    answer: 'Clave de sol',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_06',
    category: 'Partitura',
    prompt:
        'Qual clave costuma representar notas graves e a mão esquerda do piano?',
    options: [
      'Clave de sol',
      'Clave de fá',
      'Clave de dó na primeira linha',
      'Clave de percussão',
    ],
    answer: 'Clave de fá',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_07',
    category: 'Intervalos',
    prompt: 'Entre quais pares de notas naturais vizinhas há semitom?',
    options: [
      'Dó–Ré e Sol–Lá',
      'Mi–Fá e Si–Dó',
      'Ré–Mi e Fá–Sol',
      'Lá–Si e Dó–Ré',
    ],
    answer: 'Mi–Fá e Si–Dó',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_08',
    category: 'Ritmo',
    prompt:
        'Em uma fórmula de compasso 4/4, quantos tempos de semínima há em cada compasso?',
    options: ['Dois', 'Três', 'Quatro', 'Oito'],
    answer: 'Quatro',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_09',
    category: 'Ritmo',
    prompt: 'Em 4/4, qual é o valor usual de uma semínima?',
    options: ['Um tempo', 'Dois tempos', 'Três tempos', 'Quatro tempos'],
    answer: 'Um tempo',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_10',
    category: 'Ritmo',
    prompt: 'O que uma pausa representa na partitura?',
    options: [
      'Um som mais agudo',
      'Um período de silêncio',
      'Uma mudança de instrumento',
      'Um aumento obrigatório de volume',
    ],
    answer: 'Um período de silêncio',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_11',
    category: 'Elementos musicais',
    prompt: 'Qual elemento organiza sons e silêncios no tempo?',
    options: ['Ritmo', 'Timbre', 'Altura', 'Harmonia'],
    answer: 'Ritmo',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_12',
    category: 'Elementos musicais',
    prompt: 'O que distingue principalmente um som grave de um som agudo?',
    options: ['Altura', 'Duração', 'Intensidade', 'Andamento'],
    answer: 'Altura',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_13',
    category: 'Teclado',
    prompt: 'No teclado, quantos semitons separam Dó de Ré?',
    options: ['Um', 'Dois', 'Três', 'Quatro'],
    answer: 'Dois',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_14',
    category: 'Escalas',
    prompt: 'Qual é a primeira nota da escala de Dó maior?',
    options: ['Dó', 'Ré', 'Mi', 'Sol'],
    answer: 'Dó',
    difficulty: 1,
  ),
  TheoryQuestion(
    id: 'bas_15',
    category: 'Elementos musicais',
    prompt:
        'Qual característica permite reconhecer sons de instrumentos diferentes mesmo tocando a mesma nota?',
    options: ['Timbre', 'Compasso', 'Andamento', 'Intervalo'],
    answer: 'Timbre',
    difficulty: 1,
  ),

  // Intermediário
  TheoryQuestion(
    id: 'int_01',
    category: 'Escalas',
    prompt: 'Qual sequência de tons e semitons forma uma escala maior?',
    options: [
      'T–T–ST–T–T–T–ST',
      'T–ST–T–T–ST–T–T',
      'ST–T–T–T–ST–T–T',
      'T–T–T–ST–T–T–ST',
    ],
    answer: 'T–T–ST–T–T–T–ST',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_02',
    category: 'Tonalidades',
    prompt: 'Quantos sustenidos ou bemóis há na armadura de Dó maior?',
    options: ['Nenhum', 'Um sustenido', 'Um bemol', 'Dois sustenidos'],
    answer: 'Nenhum',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_03',
    category: 'Tonalidades',
    prompt: 'Qual nota é alterada na armadura de Sol maior?',
    options: ['Fá sustenido', 'Dó sustenido', 'Si bemol', 'Mi bemol'],
    answer: 'Fá sustenido',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_04',
    category: 'Tonalidades',
    prompt: 'Qual acidente aparece na armadura de Fá maior?',
    options: ['Si bemol', 'Fá sustenido', 'Mi bemol', 'Dó sustenido'],
    answer: 'Si bemol',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_05',
    category: 'Tonalidades',
    prompt: 'Quais notas são sustenidas na armadura de Ré maior?',
    options: ['Fá e Dó', 'Fá e Sol', 'Dó e Sol', 'Si e Mi'],
    answer: 'Fá e Dó',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_06',
    category: 'Intervalos',
    prompt: 'Quantos semitons formam uma oitava justa?',
    options: ['7', '10', '12', '14'],
    answer: '12',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_07',
    category: 'Intervalos',
    prompt: 'Quantos semitons há em uma quinta justa?',
    options: ['5', '7', '8', '9'],
    answer: '7',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_08',
    category: 'Acordes',
    prompt: 'Quais graus formam uma tríade maior em relação à tônica?',
    options: ['1, 3 e 5', '1, 3 e 6', '1, 4 e 5', '1, 2 e 5'],
    answer: '1, 3 e 5',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_09',
    category: 'Acordes',
    prompt: 'Qual é a terça que caracteriza uma tríade menor?',
    options: ['Terça maior', 'Terça menor', 'Quarta justa', 'Quinta diminuta'],
    answer: 'Terça menor',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_10',
    category: 'Tonalidades',
    prompt: 'Qual é a relativa menor de Dó maior?',
    options: ['Mi menor', 'Lá menor', 'Ré menor', 'Sol menor'],
    answer: 'Lá menor',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_11',
    category: 'Ritmo',
    prompt:
        'Quantos tempos de semínima são agrupados normalmente em um compasso 3/4?',
    options: ['Dois', 'Três', 'Quatro', 'Seis'],
    answer: 'Três',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_12',
    category: 'Andamento',
    prompt: 'O que indica a marcação  ♩ = 120?',
    options: [
      'A altura da nota Dó',
      '120 batidas por minuto',
      '120 compassos por música',
      'A intensidade do som',
    ],
    answer: '120 batidas por minuto',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_13',
    category: 'Alterações',
    prompt: 'O que um sustenido faz com a altura de uma nota?',
    options: [
      'Eleva um semitom',
      'Abaixa um semitom',
      'Eleva um tom inteiro',
      'Dobra sua duração',
    ],
    answer: 'Eleva um semitom',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_14',
    category: 'Alterações',
    prompt: 'O que um bemol faz com a altura de uma nota?',
    options: [
      'Eleva um semitom',
      'Abaixa um semitom',
      'Abaixa um tom inteiro',
      'Dobra sua duração',
    ],
    answer: 'Abaixa um semitom',
    difficulty: 2,
  ),
  TheoryQuestion(
    id: 'int_15',
    category: 'Ritmo',
    prompt: 'O que é síncope?',
    options: [
      'Ênfase em parte fraca do tempo ou do compasso',
      'Aceleração constante do andamento',
      'Repetição de uma nota longa',
      'Silêncio no primeiro tempo',
    ],
    answer: 'Ênfase em parte fraca do tempo ou do compasso',
    difficulty: 2,
  ),

  // Avançado
  TheoryQuestion(
    id: 'ava_01',
    category: 'Escalas',
    prompt:
        'Qual alteração diferencia a escala menor harmônica da menor natural?',
    options: [
      'Sétimo grau elevado',
      'Terceiro grau elevado',
      'Quarto grau abaixado',
      'Segundo grau elevado',
    ],
    answer: 'Sétimo grau elevado',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_02',
    category: 'Escalas',
    prompt:
        'Na forma ascendente tradicional da menor melódica, quais graus são elevados em relação à menor natural?',
    options: [
      'Sexto e sétimo',
      'Segundo e terceiro',
      'Terceiro e quinto',
      'Quarto e sexto',
    ],
    answer: 'Sexto e sétimo',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_03',
    category: 'Intervalos',
    prompt: 'Quantos semitons compõem um trítono?',
    options: ['4', '5', '6', '7'],
    answer: '6',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_04',
    category: 'Acordes',
    prompt:
        'Quais graus formam um acorde dominante com sétima (7ª da dominante)?',
    options: [
      '1, 3, 5 e 7 menor',
      '1, 3, 5 e 7 maior',
      '1, 2, 5 e 7 maior',
      '1, 4, 5 e 6',
    ],
    answer: '1, 3, 5 e 7 menor',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_05',
    category: 'Acordes',
    prompt: 'O que caracteriza uma inversão de acorde?',
    options: [
      'Uma nota diferente da fundamental passa a ser a mais grave',
      'Todas as notas são transpostas uma oitava acima',
      'O acorde muda de maior para menor',
      'As notas passam a ser tocadas em sequência',
    ],
    answer: 'Uma nota diferente da fundamental passa a ser a mais grave',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_06',
    category: 'Tonalidades',
    prompt: 'Qual é a ordem dos sustenidos nas armaduras de clave?',
    options: [
      'Fá, Dó, Sol, Ré, Lá, Mi, Si',
      'Si, Mi, Lá, Ré, Sol, Dó, Fá',
      'Dó, Sol, Ré, Lá, Mi, Si, Fá',
      'Fá, Si, Mi, Lá, Ré, Sol, Dó',
    ],
    answer: 'Fá, Dó, Sol, Ré, Lá, Mi, Si',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_07',
    category: 'Tonalidades',
    prompt: 'Quantos sustenidos há na armadura de Dó sustenido maior?',
    options: ['Cinco', 'Seis', 'Sete', 'Oito'],
    answer: 'Sete',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_08',
    category: 'Ritmo',
    prompt:
        'Em um compasso composto 6/8, quantos tempos principais são sentidos normalmente?',
    options: ['Dois', 'Três', 'Seis', 'Oito'],
    answer: 'Dois',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_09',
    category: 'Harmonia',
    prompt: 'Qual movimento harmônico é conhecido como cadência autêntica?',
    options: ['V–I', 'I–IV', 'II–V', 'IV–vi'],
    answer: 'V–I',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_10',
    category: 'Harmonia',
    prompt: 'Em Dó maior, qual é a função harmônica do acorde de Sol maior?',
    options: ['Tônica', 'Subdominante', 'Dominante', 'Mediante'],
    answer: 'Dominante',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_11',
    category: 'Modos',
    prompt:
        'Qual modo corresponde às teclas brancas do piano começando e terminando em Ré?',
    options: ['Dórico', 'Frígio', 'Lídio', 'Mixolídio'],
    answer: 'Dórico',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_12',
    category: 'Modos',
    prompt: 'Qual modo tem quarta aumentada em relação à tônica?',
    options: ['Jônio', 'Dórico', 'Lídio', 'Eólio'],
    answer: 'Lídio',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_13',
    category: 'Notação',
    prompt: 'O que são notas enarmônicas?',
    options: [
      'Notas com nomes diferentes que soam na mesma altura no sistema temperado',
      'Notas com o mesmo nome em oitavas diferentes',
      'Notas tocadas simultaneamente',
      'Notas com durações idênticas',
    ],
    answer:
        'Notas com nomes diferentes que soam na mesma altura no sistema temperado',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_14',
    category: 'Transposição',
    prompt:
        'Ao transpor uma melodia, o que deve ser preservado para manter sua identidade intervalar?',
    options: [
      'As relações de intervalo entre as notas',
      'A mesma altura absoluta de cada nota',
      'A mesma oitava em todas as notas',
      'A mesma duração para toda a música',
    ],
    answer: 'As relações de intervalo entre as notas',
    difficulty: 3,
  ),
  TheoryQuestion(
    id: 'ava_15',
    category: 'Harmonia',
    prompt: 'Qual é a sensível de uma tonalidade maior?',
    options: [
      'O quarto grau',
      'O quinto grau',
      'O sétimo grau, a um semitom da tônica',
      'O segundo grau, a um tom da tônica',
    ],
    answer: 'O sétimo grau, a um semitom da tônica',
    difficulty: 3,
  ),
  // Avançado II: leitura harmônica, análise e percepção aplicada.
  TheoryQuestion(
    id: 'av2_01',
    category: 'Harmonia',
    prompt: 'Em Dó maior, qual acorde é o ii grau diatônico?',
    options: ['Ré menor', 'Ré maior', 'Mi menor', 'Fá maior'],
    answer: 'Ré menor',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_02',
    category: 'Harmonia',
    prompt: 'Qual sequência representa uma cadência plagal em Dó maior?',
    options: [
      'Fá maior–Dó maior',
      'Sol maior–Dó maior',
      'Dó maior–Sol maior',
      'Ré menor–Sol maior',
    ],
    answer: 'Fá maior–Dó maior',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_03',
    category: 'Acordes',
    prompt: 'Qual é a tríade diminuta construída sobre Si em Dó maior?',
    options: [
      'Si–Ré–Fá',
      'Si–Ré sustenido–Fá sustenido',
      'Si–Mi–Sol',
      'Si–Ré–Fá sustenido',
    ],
    answer: 'Si–Ré–Fá',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_04',
    category: 'Ritmo',
    prompt: 'Quantas colcheias compõem um compasso de 6/8?',
    options: ['Três', 'Quatro', 'Seis', 'Oito'],
    answer: 'Seis',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_05',
    category: 'Acordes',
    prompt:
        'Qual nota fica no baixo de um acorde de Dó maior em primeira inversão?',
    options: ['Dó', 'Mi', 'Sol', 'Si'],
    answer: 'Mi',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_06',
    category: 'Acordes',
    prompt:
        'Quais notas formam o acorde de Sol com sétima da dominante (Sol7)?',
    options: [
      'Sol, Si, Ré e Fá',
      'Sol, Si, Ré e Fá sustenido',
      'Sol, Si bemol, Ré e Fá',
      'Sol, Dó, Ré e Fá',
    ],
    answer: 'Sol, Si, Ré e Fá',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_07',
    category: 'Harmonia',
    prompt:
        'Qual acorde prepara com frequência a dominante em uma progressão funcional?',
    options: ['Subdominante', 'Tônica', 'Mediante', 'Sensível'],
    answer: 'Subdominante',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_08',
    category: 'Notação',
    prompt: 'O que informa a armadura de clave de uma peça?',
    options: [
      'Quais notas recebem alterações recorrentes ao longo da peça',
      'Que a peça deve ser tocada suave',
      'Que todas as notas duram metade',
      'Que a tonalidade é necessariamente menor',
    ],
    answer: 'Quais notas recebem alterações recorrentes ao longo da peça',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_09',
    category: 'Acordes',
    prompt: 'Qual acorde é formado pelas notas Lá, Dó e Mi?',
    options: ['Lá maior', 'Lá menor', 'Dó maior', 'Mi diminuto'],
    answer: 'Lá menor',
    difficulty: 4,
  ),
  TheoryQuestion(
    id: 'av2_10',
    category: 'Tonalidades',
    prompt: 'Qual tonalidade maior possui três bemóis na armadura?',
    options: [
      'Mi bemol maior',
      'Lá bemol maior',
      'Si bemol maior',
      'Ré bemol maior',
    ],
    answer: 'Mi bemol maior',
    difficulty: 4,
  ),
  // Especialista: análise de função, modos, condução e forma.
  TheoryQuestion(
    id: 'esp_01',
    category: 'Harmonia',
    prompt:
        'Em Dó maior, qual é a resolução mais comum do acorde de sétima da dominante?',
    options: [
      'Sol7 para Dó',
      'Fá7 para Sol',
      'Ré7 para Lá menor',
      'Dó7 para Fá',
    ],
    answer: 'Sol7 para Dó',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_02',
    category: 'Harmonia',
    prompt: 'Qual nota é a sensível de Lá menor harmônica?',
    options: ['Sol sustenido', 'Sol natural', 'Fá sustenido', 'Si bemol'],
    answer: 'Sol sustenido',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_03',
    category: 'Modos',
    prompt: 'Qual característica intervalar destaca o modo frígio?',
    options: [
      'Segundo grau menor',
      'Quarta aumentada',
      'Sexto grau maior',
      'Sétimo grau maior',
    ],
    answer: 'Segundo grau menor',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_04',
    category: 'Condução de vozes',
    prompt:
        'Na condução de vozes tradicional, por que se evita frequentemente o movimento paralelo de quintas?',
    options: [
      'Porque reduz a independência das vozes',
      'Porque torna o acorde sempre dissonante',
      'Porque muda a fórmula de compasso',
      'Porque impede a resolução da sensível',
    ],
    answer: 'Porque reduz a independência das vozes',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_05',
    category: 'Acordes',
    prompt:
        'Qual conjunto de intervalos forma uma tétrade meio-diminuta (m7(b5))?',
    options: [
      '1, 3 menor, 5 diminuta e 7 menor',
      '1, 3 menor, 5 diminuta e 7 diminuta',
      '1, 3 maior, 5 justa e 7 menor',
      '1, 3 maior, 5 aumentada e 7 maior',
    ],
    answer: '1, 3 menor, 5 diminuta e 7 menor',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_06',
    category: 'Harmonia',
    prompt: 'Em Dó maior, qual acorde é dominante secundária de Ré menor?',
    options: [
      'Lá maior ou Lá7',
      'Mi maior ou Mi7',
      'Sol maior ou Sol7',
      'Si bemol maior',
    ],
    answer: 'Lá maior ou Lá7',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_07',
    category: 'Forma musical',
    prompt: 'Em uma forma ABA, o que acontece na seção final A?',
    options: [
      'Retorna o material temático inicial',
      'Surge sempre um tema totalmente novo',
      'A música muda obrigatoriamente de compasso',
      'A seção B é repetida sem alterações',
    ],
    answer: 'Retorna o material temático inicial',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_08',
    category: 'Intervalos',
    prompt: 'Qual intervalo composto corresponde a uma nona maior?',
    options: [
      'Oitava mais uma segunda maior',
      'Oitava mais uma segunda menor',
      'Duas oitavas',
      'Oitava mais uma terça menor',
    ],
    answer: 'Oitava mais uma segunda maior',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_09',
    category: 'Escalas',
    prompt:
        'Qual modo diatônico se ajusta à tríade maior com sétima menor de um acorde dominante?',
    options: ['Mixolídia', 'Lídia', 'Jônia', 'Dórica'],
    answer: 'Mixolídia',
    difficulty: 5,
  ),
  TheoryQuestion(
    id: 'esp_10',
    category: 'Harmonia',
    prompt:
        'O que caracteriza uma resolução deceptiva V–vi em tonalidade maior?',
    options: [
      'A dominante resolve no sexto grau em vez da tônica',
      'A tônica resolve no quinto grau',
      'A subdominante substitui a dominante',
      'O acorde dominante perde a terça',
    ],
    answer: 'A dominante resolve no sexto grau em vez da tônica',
    difficulty: 5,
  ),
];
