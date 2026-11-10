# Tarefas para o Codex — Melody Hub

Leia o `AGENTS.md` na raiz antes de começar. Execute as tarefas **em ordem**, uma por commit.
Cada tarefa traz o objetivo, onde mexer e o critério de aceite. Ao terminar cada uma,
preencha o bloco **Registro** dela.

Fora de escopo nesta rodada: painel de administrador, conteúdo baseado em músicas
favoritas e notificações push remotas.

---

## Tarefa 1 — Extrair as regras de gamificação e testá-las

**Por quê:** `ProgressService.registrarExercicio` tem cerca de 340 linhas de regra de
negócio dentro de uma transação do Firestore, então não pode ser testada. O TCC exige
testes da gamificação (XP, streak, níveis). Além disso, `XpCalculator` não é usado e o
valor 10 está fixo no serviço.

**O que fazer:**
1. Criar `lib/domain/progress_rules.dart` com uma função pura, sem Firebase, por exemplo:
   ```dart
   ResultadoExercicio aplicarExercicio({
     required Map<String, dynamic> dados,   // documento atual do usuário
     required bool acertou,
     required String tipo,
     int? dificuldade,
     required DateTime agora,
   });
   ```
   `ResultadoExercicio` traz: o mapa de campos a gravar no perfil, `xpGanho`,
   `pontosGanhos` e a lista de conquistas novas.
2. Mover para lá **toda** a regra que hoje está em `registrarExercicio`: XP, pontos,
   nível por XP, sequência de respostas, sequência de dias, níveis e etapas de teoria,
   prática, intervalos e habilidades (ritmo, escalas e acordes), e a verificação de
   conquistas. Mover também `calcularNivel`, `xpParaProximoNivel`, `xpNivelAnterior` e
   `proximoNivel`, mantendo métodos no `ProgressService` que deleguem para as novas
   funções, para não quebrar as telas.
3. Usar `XpCalculator.calculateXp` para o XP (ou remover `XpCalculator` e o teste dele
   e centralizar em `progress_rules.dart`; escolha um e registre).
4. `registrarExercicio` passa a só ler o documento, chamar `aplicarExercicio` e gravar
   o resultado e o evento de histórico na mesma transação.
5. **O comportamento tem que continuar idêntico.** Campos gravados, nomes e valores
   não mudam.
6. Criar `test/progress_rules_test.dart` cobrindo pelo menos:
   - XP +10 no acerto e 0 no erro; pontos `8 + 2 × dificuldade` (dificuldade entre 1 e 5) no acerto e 5 no erro;
   - nível por XP nos limites 99/100, 249/250, 499/500 e 999/1000;
   - avanço de nível de teoria com 7 acertos em 10, sem avanço com 6 em 10 e sem passar de 5;
   - o mesmo para prática e intervalos, incluindo a marcação de `concluida` na etapa;
   - etapas de ritmo, escalas e acordes em `habilidadesEtapas`;
   - sequência de dias: mesmo dia, dia seguinte (+1), dia pulado (volta a 1) e virada de mês;
   - conquistas `primeiro_exercicio`, `dez_acertos` e `sequencia_cinco`, sem duplicar conquista já obtida.
7. O teste em `integration_test/login_test.dart` está quebrado: não monta o app e o pacote
   `integration_test` não está no `pubspec.yaml`. Substitua-o por um widget test em
   `test/login_page_test.dart` que monte `LoginPage` dentro de um `MaterialApp`
   (use `SharedPreferences.setMockInitialValues({})`) e verifique os campos de e-mail e
   senha e o botão de entrar. Se `LoginPage` exigir Firebase só para ser montada, isole
   essa dependência da forma mais simples possível. Depois apague a pasta `integration_test/`.

**Aceite:** `flutter test` passa com os testes novos; `registrarExercicio` tem menos
de 60 linhas; nenhuma tela foi alterada além de imports.

**Registro:**
- Arquivos: `lib/domain/progress_rules.dart`, `lib/services/progress_service.dart`, `test/progress_rules_test.dart`, `test/login_page_test.dart`; removido `integration_test/login_test.dart`.
- Decisões: `XpCalculator.calculateXp` foi mantido e reutilizado; o timestamp do Firestore é convertido no serviço para `DateTime`, mantendo o domínio sem dependências externas. Perfil e histórico continuam sendo gravados na mesma transação.
- Pendências: nenhuma para esta tarefa.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (inclui os testes novos de regras de progresso e de montagem da tela de login).
- Complemento: cobertos o fallback de sequência com `ultimoExercicio` legado (`DateTime`) e a conclusão de etapa teórica abaixo do nível atual, sem alterar a rodada corrente; datas passaram a usar `StudyStreak.dateKey`.

---

## Tarefa 2 — Recuperar senha e cadastro consistente

**O que fazer:**
1. Em `lib/screens/login_page.dart`, adicionar o link "Esqueci minha senha" abaixo do
   campo de senha. Ele usa o e-mail digitado (ou pede um, se o campo estiver vazio) e
   chama `FirebaseAuth.instance.sendPasswordResetEmail`. Mensagens em português para
   sucesso, `invalid-email`, `user-not-found` e erro genérico. Por segurança, a mensagem
   de sucesso pode ser a mesma quando o e-mail não existe.
2. Em `lib/screens/register_page.dart`: se a gravação do documento no Firestore falhar
   depois de `createUserWithEmailAndPassword`, chamar `usuario.delete()` para não deixar
   uma conta sem perfil, e mostrar o erro.

**Aceite:** o fluxo funciona com e-mail válido e com campo vazio; `flutter analyze` está limpo.

**Registro:**
- Arquivos: `lib/screens/login_page.dart`, `lib/screens/register_page.dart`, `test/login_page_test.dart`.
- Decisões: quando o campo estiver vazio, a recuperação solicita o e-mail em diálogo; sucesso e `user-not-found` usam a mesma resposta para não revelar a existência da conta. Falha ao criar o perfil no Firestore tenta excluir a conta recém-criada e mostra uma mensagem de perfil não salvo.
- Pendências: envio real de e-mail e compensação no Firebase dependem de credenciais/serviços configurados e não foram executados em integração; os fluxos de interface foram cobertos por widget test.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou.

---

## Tarefa 3 — Regras de segurança do Firebase versionadas

**O que fazer:**
1. Criar `firestore.rules`:
   - `usuarios/{uid}` e `usuarios/{uid}/historico/{eventoId}`: leitura e escrita só se
     `request.auth != null && request.auth.uid == uid`;
   - no documento do usuário, validar que `xp`, `pontos` e `nivel`, quando presentes, são
     números maiores ou iguais a 0;
   - negar todo o resto.
2. Criar `storage.rules`: `profilePhotos/{uid}/{arquivo}` com leitura para usuário
   autenticado e escrita só para o dono, `contentType` de imagem e tamanho menor que 5 MB.
   O caminho usado pelo app está em `profile_screen.dart`: `profilePhotos/${uid}/avatar.png|jpg`.
3. Referenciar os dois arquivos em `firebase.json` (chaves `firestore.rules` e `storage.rules`),
   sem remover a configuração `flutter` que já existe.
4. Adicionar ao `README.md` uma seção "Regras de segurança" explicando como publicar
   (`firebase deploy --only firestore:rules,storage`) e o limite conhecido: XP e pontos são
   calculados no cliente, então as regras impedem acesso a dados de outras contas, mas não
   impedem fraude na própria conta.

**Não publique as regras.** Só crie os arquivos.

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Tarefa 4 — Nomenclatura de notas (cifra ou solfejo) em todo o app

**Por quê:** a preferência cifra/solfejo do perfil só vale no teclado livre e nas
escalas e acordes. O violão (`guitar_fretboard_screen.dart`), o teclado de resposta
(`widgets/piano_answer_keyboard.dart`), os intervalos (`interval_exercises_screen.dart`)
e a prática (`exercises_screen.dart`) têm nomes em solfejo fixos no código. O caso de uso
do TCC também pede que a preferência seja persistida no perfil (banco), não só no aparelho.

**O que fazer:**
1. Criar `lib/utils/note_names.dart` com as listas de cifra
   (`C, C♯, D, …, B`) e de solfejo (`Dó, Dó♯, Ré, …, Si`) e uma função
   `String nomeNota(int midiOuClasse, String tipo)`, além de uma variante por extenso
   ("Dó sustenido"), se alguma tela precisar.
2. Trocar as listas fixas dessas quatro telas e do `keyboard_screen.dart` /
   `music_concepts_screen.dart` pela função nova, lendo `AppPreferences.noteType()`.
   `PianoAnswerKeyboard` recebe um parâmetro `tipoNota`.
3. Persistência na nuvem: ao alterar no perfil, gravar também
   `usuarios/{uid}.preferencias.nomenclatura` (`'cifragem'` ou `'solfejo'`). Ao abrir o
   app autenticado (por exemplo, no `initState` do `AppShell`), se o Firestore tiver um
   valor, copiá-lo para o `AppPreferences` local. O local continua valendo como cache.
4. Os textos de histórico já gravados não mudam. Só a exibição nova usa a preferência.

**Aceite:** trocar para "C–D–E" no perfil muda os rótulos no violão, nos teclados e nos
textos dos exercícios; a preferência volta após reinstalar o app ou entrar em outro aparelho.
Adicione um teste unitário simples para `note_names.dart`.

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Tarefa 5 — Filtro por instrumento no catálogo e exercício no violão

**Por quê:** o caso de uso "Filtrar por Categoria de Instrumento" pede um filtro
Teclado/Violão na tela de exploração, mostrando só os desafios compatíveis, abrindo o
simulador correspondente e mantendo a preferência. Hoje nenhum exercício usa o violão,
então o filtro ficaria vazio.

**O que fazer:**
1. Extrair o braço do violão de `guitar_fretboard_screen.dart` (`_FretboardGeometry`,
   `_FretboardPainter` e o tratamento de toque e arraste) para um widget reutilizável
   `lib/widgets/guitar_fretboard.dart`, com callback `onPositionPressed(int corda, int casa, int midi)`
   e opção de mostrar os nomes das notas. A tela do simulador passa a usar o widget,
   com o mesmo visual e comportamento.
2. Criar `lib/screens/guitar_note_exercise_screen.dart`: o app toca uma nota
   (sample via `GuitarSampleMap`), o aluno a encontra no braço, e **qualquer posição com o
   mesmo MIDI conta como acerto**. Com feedback, botão de repetir, dica (corda e casa de
   uma posição possível) e explicação após erro. Registrar com
   `registrarExercicio(tipo: 'Violão', categoria: 'Violão: identificar notas', …)`,
   preenchendo pergunta, resposta, resposta correta e duração, como os outros exercícios.
   Use as notas das casas 0–5 no nível inicial; sem trilha de níveis nesta tarefa.
3. Em `exercise_catalog_screen.dart`: adicionar a cada atividade uma lista
   `instrumentos` (`'Teclado'`, `'Violão'` ou nenhuma). Prática, Intervalos e Acordes →
   Teclado; o exercício novo → Violão; Teoria, Ritmo e Escalas → nenhuma (aparecem só em "Todos").
   Adicionar o filtro "Instrumento: Todos / Teclado / Violão", salvo e restaurado com
   `AppPreferences.catalogInstrument()` / `setCatalogInstrument()`, que já existem.
4. Quando o filtro for Teclado ou Violão, mostrar no topo da lista um cartão
   "Abrir simulador de <instrumento>" que abre `KeyboardScreen` ou `GuitarFretboardScreen`.
5. Garantir que `performance_screen.dart` e `history_screen.dart` exibem o tipo `'Violão'`
   sem quebrar (rótulo e ícone).

**Aceite:** o filtro persiste ao sair e voltar da tela; Violão mostra o exercício novo e o
atalho do simulador; o simulador de violão continua funcionando como antes.

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Tarefa 6 — Lembrete com dias da semana

**Por quê:** o caso de uso "Configurar Lembrete de Estudo" inclui "Definir Horário e
Recorrência". Hoje o lembrete é só diário.

**O que fazer:**
1. Em `AppPreferences`: guardar a lista de dias selecionados (`List<int>` de 1 a 7,
   segunda a domingo; padrão: todos).
2. Em `ReminderService`: `scheduleWeekly({required int hour, required int minute, required List<int> dias})`,
   agendando uma notificação por dia com `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`
   e IDs `7360 + dia`. O cancelamento remove todos (7360–7367) e também o antigo 7357.
   Manter `showAchievement` como está.
3. Em `profile_screen.dart`: chips "S T Q Q S S D" abaixo do horário do lembrete; ao
   alterar, reagendar. Pelo menos um dia precisa ficar selecionado.

**Aceite:** ativar, trocar horário e trocar dias reagenda sem duplicar; desativar cancela tudo.

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Tarefa 7 — Itens críticos no relatório (o que o aluno mais erra)

**Por quê:** o caso de uso "Visualizar Estatísticas de Erros" pede identificar
notas e intervalos críticos. O relatório atual só agrupa por categoria.

**O que fazer:**
1. Adicionar ao `registrarExercicio` um parâmetro opcional `String? itemAvaliado`,
   gravado no evento de histórico. Preencher:
   - Intervalos: o nome do intervalo (ex.: "Terça maior");
   - Prática com nota única e exercício de violão: o nome da nota em solfejo, para padronizar;
   - Escalas e Acordes: o tipo sorteado (ex.: "Menor harmônica", "Acorde diminuto");
   - Teoria: `categoria` da questão.
2. Em `performance_screen.dart`, nova seção "O que mais precisa de revisão": agrupar os
   erros dos últimos 7 dias por `tipo + itemAvaliado`, mostrar os até 5 itens com mais
   erros (mínimo de 2 erros cada), com "X erros em Y tentativas" e um botão para abrir o
   exercício correspondente. Registros antigos sem `itemAvaliado` são ignorados. Sem dados
   suficientes, mostrar uma mensagem explicando.
3. Colocar o cálculo do agrupamento numa função pura (por exemplo, em
   `lib/domain/report_rules.dart`) e testá-la.

**Aceite:** depois de errar duas vezes a mesma terça maior, ela aparece na seção; o teste
do agrupamento passa.

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Ao final de todas as tarefas

Atualize o `README.md` (seções de funcionalidades e de dados no Firestore) com os campos
novos: `preferencias.nomenclatura`, `itemAvaliado` e o tipo `'Violão'`. Corrija também a
frase que diz que os ícones da loja são "espaços reservados", porque as imagens já existem.
