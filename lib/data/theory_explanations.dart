class TheoryExplanation {
  const TheoryExplanation({
    required this.objective,
    required this.theory,
    this.song,
  });

  final String objective;
  final String theory;
  final String? song;
}

const intervalTheory = <int, TheoryExplanation>{
  1: TheoryExplanation(
    objective: 'Ouvir a menor distância entre duas notas.',
    theory:
        'A menor distância é um semitom: uma tecla para a vizinha, contando também as pretas. Ela costuma soar tensa.',
    song: 'Tema do filme Tubarão',
  ),
  2: TheoryExplanation(
    objective: 'Reconhecer um passo de escala.',
    theory:
        'Dois semitons formam um tom. É a distância entre duas teclas vizinhas pulando uma tecla no meio.',
    song: 'Parabéns a você, de “ra” para “béns”',
  ),
  3: TheoryExplanation(
    objective: 'Reconhecer uma terça menor.',
    theory:
        'Três semitons formam um tom e meio. A terça menor é comum em acordes menores e pode soar mais escura.',
    song: 'Smoke on the Water, primeiras notas',
  ),
  4: TheoryExplanation(
    objective: 'Reconhecer uma terça maior.',
    theory:
        'Quatro semitons formam dois tons. A terça maior define a sonoridade de muitos acordes maiores.',
    song: 'Oh When the Saints',
  ),
  5: TheoryExplanation(
    objective: 'Reconhecer uma quarta justa.',
    theory:
        'Cinco semitons formam dois tons e meio. É um salto firme, usado em melodias e acordes.',
    song: 'Marcha nupcial (“Lá vem a noiva”)',
  ),
  6: TheoryExplanation(
    objective: 'Reconhecer o trítono.',
    theory:
        'Seis semitons dividem a oitava exatamente ao meio. O som é instável e costuma pedir continuação.',
    song: 'Abertura de Os Simpsons',
  ),
  7: TheoryExplanation(
    objective: 'Reconhecer uma quinta justa.',
    theory:
        'Sete semitons formam três tons e meio. A quinta justa soa aberta e estável, e é comum em power chords.',
    song: 'Brilha, brilha, estrelinha, de “bri” ao segundo “bri”',
  ),
  8: TheoryExplanation(
    objective: 'Reconhecer uma sexta menor.',
    theory:
        'Oito semitons formam quatro tons. É um intervalo amplo, frequentemente descrito como suave ou melancólico.',
  ),
  9: TheoryExplanation(
    objective: 'Reconhecer uma sexta maior.',
    theory:
        'Nove semitons formam quatro tons e meio. É um salto amplo, com sonoridade luminosa.',
    song: 'My Bonnie',
  ),
  10: TheoryExplanation(
    objective: 'Reconhecer uma sétima menor.',
    theory:
        'Dez semitons formam cinco tons. A sétima menor aparece muito no blues e em acordes dominantes.',
    song: 'Tema original de Star Trek',
  ),
  11: TheoryExplanation(
    objective: 'Reconhecer uma sétima maior.',
    theory:
        'Onze semitons deixam a nota a um semitom da oitava. Esse intervalo cria tensão e expectativa.',
  ),
  12: TheoryExplanation(
    objective: 'Reconhecer a mesma nota em outra oitava.',
    theory:
        'Doze semitons formam uma oitava. As notas têm nomes iguais, mas uma soa mais aguda que a outra.',
    song: 'Somewhere Over the Rainbow, “Some-where”',
  ),
};

const practiceNoteTheory = TheoryExplanation(
  objective: 'Comparar a altura de notas com uma referência conhecida.',
  theory:
      'Cada nota tem uma altura. Compare com o Dó: à direita no teclado o som fica mais agudo, à esquerda fica mais grave. A escala natural segue Dó, Ré, Mi, Fá, Sol, Lá e Si.',
);

const registerTheory = TheoryExplanation(
  objective: 'Perceber se uma nota está mais aguda ou mais grave.',
  theory:
      'Notas agudas soam finas, como um apito; notas graves soam mais encorpadas, como um trovão. No teclado, as notas ficam mais agudas da esquerda para a direita.',
);

String theoryObjectiveForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('ritmo') || normalized.contains('compasso')) {
    return 'Entender como durações e silêncios organizam a música no tempo.';
  }
  if (normalized.contains('escala')) {
    return 'Perceber a sequência de notas e os intervalos que formam uma escala.';
  }
  if (normalized.contains('acorde') || normalized.contains('harmonia')) {
    return 'Perceber como notas tocadas juntas formam um acorde.';
  }
  if (normalized.contains('interval')) {
    return 'Reconhecer a distância entre notas pelo som.';
  }
  return 'Compreender o conceito musical “$category”.';
}
