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
- Arquivos: `firestore.rules`, `storage.rules`, `firebase.json`, `README.md`.
- Decisões: campos numéricos aceitam `int` ou `float`; leitura das fotos exige autenticação e gravação exige propriedade, MIME de imagem e tamanho abaixo de 5 MiB. Nenhum deploy foi feito.
- Pendências: compilação das regras pelo Emulator Suite não foi possível porque o ambiente tem Java anterior ao 21 exigido pelo Firebase CLI 15.18.0.
- analyze/test: `firebase.json` validado como JSON; `flutter analyze` sem problemas; `flutter test` passou.

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
- Arquivos: `lib/utils/note_names.dart`, telas de violão, prática, intervalos, teclado, conceitos musicais e perfil, `lib/widgets/piano_answer_keyboard.dart`, `lib/screens/app_shell.dart`, `test/note_names_test.dart`.
- Decisões: a cifra e o solfejo são renderizados a partir da classe MIDI; o nome por extenso usa solfejo português. A nomenclatura local é cache e a preferência válida do Firestore sincroniza ao abrir o `AppShell` autenticado.
- Pendências: não foi possível validar sincronização entre contas/dispositivos sem sessão Firebase de teste; leitura e gravação têm fallback local.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou, incluindo o teste de nomes de notas.

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
- Arquivos: `lib/widgets/guitar_fretboard.dart`, `lib/screens/guitar_fretboard_screen.dart`, `lib/screens/guitar_note_exercise_screen.dart`, `lib/screens/exercise_catalog_screen.dart`, `lib/screens/history_screen.dart`, `lib/screens/performance_screen.dart`.
- Decisões: o braço expõe callback com corda, casa e MIDI e mantém a geometria visual e captura de arraste; o exercício usa alvo entre casas 0–5, mas aceita somente posições cujo MIDI seja exatamente igual. O filtro mantém os valores definidos em `AppPreferences`.
- Pendências: teste de interação com áudio real e navegação em dispositivo não foi executado; emulação automatizada não verifica reprodução de samples.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou.

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
- Arquivos: `lib/services/app_preferences.dart`, `lib/services/reminder_service.dart`, `lib/screens/profile_screen.dart`, `test/reminder_days_test.dart`.
- Decisões: dias são salvos como strings no `SharedPreferences` por compatibilidade com a API de lista já usada, validados e normalizados como inteiros de 1 a 7; vazio usa semana completa como padrão. IDs semanais são `7360 + dia`; o cancelamento remove 7357 e 7360–7367 antes de reagendar.
- Pendências: notificações agendadas requerem permissão e validação no sistema móvel; não há dispositivo de notificação real disponível nesta rodada.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou, incluindo persistência e validação dos dias.

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
- Arquivos: `lib/services/progress_service.dart`, telas de intervalos, prática, violão, teoria e escalas/acordes, `lib/domain/report_rules.dart`, `lib/screens/performance_screen.dart`, `test/report_rules_test.dart`.
- Decisões: agrupamento considera eventos dos últimos sete dias com `itemAvaliado`, ordena por erros, limita a cinco e exige pelo menos dois erros. Notas práticas e de violão são padronizadas em solfejo no campo analítico, independente da preferência de exibição.
- Pendências: registros antigos sem `itemAvaliado` não podem ser agrupados, conforme solicitado; eventos com data ausente ou sem `DateTime` também são ignorados.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou, incluindo agrupamento, recorte temporal, mínimo de erros e limite de itens.

---

## Ao final de todas as tarefas

Atualize o `README.md` (seções de funcionalidades e de dados no Firestore) com os campos
novos: `preferencias.nomenclatura`, `itemAvaliado` e o tipo `'Violão'`. Corrija também a
frase que diz que os ícones da loja são "espaços reservados", porque as imagens já existem.


---

# Rodada 2

Mesmas regras do `AGENTS.md`: uma tarefa por commit, com `flutter analyze` e `flutter test`
passando e o bloco **Registro** preenchido. **Não publique regras do Firebase**: a
publicação está pausada até o autor confirmar (ver `docs/publicacao-regras-firebase.md`).

## Tarefa 8 — Remover o envio de foto de perfil (Storage indisponível)

**Por quê:** o Firebase Storage não está ativo no projeto, e no plano gratuito (Spark) ele
exige o plano Blaze. O botão de foto do perfil falha sempre. A personalização do perfil já
é atendida por nome, ícones da loja e preferências.

**O que fazer:**
1. Em `lib/screens/profile_screen.dart`, remover a opção de enviar foto e o código de
   `ImagePicker` e `FirebaseStorage`. O avatar passa a mostrar o ícone escolhido ou, se não
   houver, a inicial do nome. Pode continuar lendo `fotoUrl` se ela existir, mas sem
   oferecer o envio.
2. Remover `firebase_storage` e `image_picker` do `pubspec.yaml`, se não forem usados em
   outro lugar, e rodar `flutter pub get`. Remover também permissões de câmera ou galeria
   que tenham sido adicionadas só para isso (AndroidManifest e Info.plist), se existirem.
3. Remover a entrada `storage` do `firebase.json` e apagar `storage.rules`, para que um
   `firebase deploy` sem `--only` não falhe.
4. No `README.md`, trocar a menção à foto por: "Foto de perfil fora do escopo: requer
   Firebase Storage (plano Blaze)".

**Aceite:** o perfil abre sem o botão de foto; o app compila sem os dois pacotes; analyze e test passam.

**Registro:**
- Arquivos: `lib/screens/profile_screen.dart`, `pubspec.yaml`, `pubspec.lock`, `firebase.json`, `README.md`, arquivos de registro de plugins Flutter em `linux/`, `macos/` e `windows/`; removido `storage.rules`.
- Decisões: o avatar continua exibindo `fotoUrl` antiga quando presente; sem foto, mostra o ícone escolhido ou a inicial do nome. A busca por permissões específicas de câmera/galeria em Android e iOS não encontrou declarações a remover. A configuração gerada do Firebase foi mantida.
- Pendências: envio de foto permanece fora do escopo até o Firebase Storage estar disponível; nenhuma migração foi feita nos dados existentes.
- analyze/test: `flutter pub get` removeu `firebase_storage`, `image_picker` e plugins transitivos; `flutter analyze` sem problemas; `flutter test` passou (31 testes).

---

## Tarefa 9 — Feedback adaptado ao nível do aluno (entrevista com o consultor)

**Por quê:** o consultor pediu que o detalhe do feedback acompanhe o nível do aluno:
o iniciante recebe apoio e não é sobrecarregado com o erro; o avançado recebe o erro
exato e menos ajuda prévia.

**O que fazer:**
1. Criar `lib/domain/feedback_rules.dart` com uma função pura, por exemplo
   `NivelApoio nivelDeApoio({required int nivelEtapa, required int sequenciaAcertos})`,
   que retorna `iniciante` (etapa 1–2), `intermediario` (etapa 3) ou `avancado`
   (etapa 4–5, ou 5+ acertos seguidos na sessão). Com testes em `test/feedback_rules_test.dart`.
2. Em `interval_exercises_screen.dart`:
   - **iniciante:** mostra o nome da nota inicial; após um erro, toca automaticamente a
     resposta correta (nota inicial e depois a nota de chegada) e mostra uma explicação
     curta e encorajadora (uma frase, sem a contagem de semitons);
   - **intermediário:** comportamento atual;
   - **avançado:** não mostra o nome da nota inicial (só o som); após um erro, mostra a
     explicação completa: nota tocada × nota correta e a distância em semitons de cada uma.
3. Aplicar a mesma ideia em `exercises_screen.dart` (prática de notas): no iniciante, após
   um erro, tocar a sequência correta automaticamente; no avançado, indicar a posição
   exata do primeiro erro na sequência ("3ª nota: você tocou Fá, era Sol").
4. A sequência de acertos da sessão fica só em memória, na tela. Nada novo no Firestore.

**Aceite:** os três níveis são visíveis trocando de etapa; os testes da função passam.

**Registro:**
- Arquivos: `lib/domain/feedback_rules.dart`, `lib/screens/interval_exercises_screen.dart`, `lib/screens/exercises_screen.dart`, `test/feedback_rules_test.dart`.
- Decisões: etapas 1–2 usam apoio iniciante, etapa 3 intermediário, etapas 4–5 avançado; cinco acertos seguidos elevam o apoio em qualquer etapa. A sequência da sessão permanece em memória nas telas. Após erro iniciante, a resposta correta é tocada automaticamente; nos intervalos avançados, o feedback compara a nota tocada e a correta em semitons; na prática avançada, aponta a posição ordinal do primeiro erro.
- Pendências: reprodução de áudio e transição entre etapas precisam de validação manual em dispositivo; nenhum campo novo foi gravado no Firestore.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (36 testes, incluindo cinco testes novos das regras de apoio).

---

## Tarefa 10 — Testes de widget dos fluxos novos

**Por quê:** o critério de aceitação do TCC pede testes além dos unitários. As telas novas
podem ser testadas sem Firebase.

**O que fazer:**
1. `test/exercise_catalog_test.dart`: montar `ExerciseCatalogScreen` com
   `SharedPreferences.setMockInitialValues({})`; selecionar "Violão" e verificar que só
   aparecem o exercício de violão e o atalho do simulador; remontar a tela e verificar que
   o filtro continua "Violão".
2. `test/guitar_fretboard_test.dart`: montar o widget `GuitarFretboard` e simular um toque
   numa posição conhecida (corda e casa) e verificar que o callback recebe o MIDI correto
   (por exemplo, a 5ª corda, casa 3, dá MIDI 48, o Dó).
3. Se alguma tela depender de Firebase ou do áudio só para ser montada, injetar a
   dependência pelo construtor, com padrão igual ao atual, em vez de criar mocks complexos.
   Registrar o que foi alterado.

**Aceite:** os novos testes passam junto com os existentes.

**Registro:**
- Arquivos: `test/exercise_catalog_test.dart`, `test/guitar_fretboard_test.dart`.
- Decisões: o catálogo é montado sem navegar para telas que usam Firebase; o filtro de instrumento é restaurado após remontar a tela com SharedPreferences simulado. O teste do braço toca a posição pela geometria dos trastes, sem alterar o widget nem injetar áudio, e confirma corda 5/casa 3/MIDI 48.
- Pendências: validação limitada ao widget e ao callback; toque físico e áudio do simulador não foram testados.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (38 testes, incluindo os dois novos testes de widget).

---

## Tarefa 11 (opcional) — Assinatura de release separada da chave de debug

**O que fazer:** em `android/app/build.gradle` (ou `.kts`), ler `android/key.properties` quando
o arquivo existir e usar essa configuração de assinatura no `release`; sem o arquivo, manter
a assinatura de debug atual. Adicionar `key.properties` e `*.jks` ao `.gitignore`. Documentar
no README como gerar a chave com `keytool`. **Não gere nem commite chaves.**

**Registro:**
- Arquivos:
- Decisões:
- Pendências:
- analyze/test:

---

## Tarefa 13 — Melhorias didáticas, samples e interface musical

### Registro 13A — Biblioteca de samples
- Arquivos: `assets/sounds/piano/`, `assets/sounds/guitar/`, `lib/utils/sample_map.dart`, `lib/utils/guitar_sample_map.dart`, telas de teclado, prática, intervalos, conceitos musicais e violão, `lib/screens/profile_screen.dart`, `pubspec.yaml`, `test/sound_assets_test.dart` e `docs/creditos-sons.md`; removidos os samples antigos substituídos. Preservados os três WAVs de metrônomo/ditado rítmico.
- Decisões: samples de `nbrosowsky/tonejs-instruments`, áudio sob CC BY 3.0. A seleção MIDI central só aceita deslocamento de até um semitom. Atribuições e origens específicas estão em `docs/creditos-sons.md` e no Perfil.
- Pendências: conferir auditivamente os timbres em aparelho físico; essa etapa não é automatizável aqui.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (45 testes); APK release 78,1 MB, abaixo dos 85.706.766 bytes do APK anterior.

### Registro 13B — Braço em paisagem
- Arquivos: `lib/screens/guitar_fretboard_screen.dart`, `lib/screens/guitar_note_exercise_screen.dart`, `lib/widgets/guitar_fretboard.dart` e `test/guitar_fretboard_test.dart`.
- Decisões: o braço usa a altura disponível sem teto fixo; largura mínima rolável de 1240 dp para manter as casas mais curtas acima de 40 dp. As etiquetas usam no máximo 80% do espaçamento vertical. Instruções do simulador ficam num bottom sheet acessível pelo ícone de informação; cabeçalho e controles do exercício foram compactados.
- Pendências: toque e rolagem precisam de validação manual em um celular real.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (46 testes), incluindo 800×360 e quinta corda/casa 3/MIDI 48.

### Registro 13C — Extensão do teclado
- Arquivos: `lib/screens/keyboard_screen.dart`, `lib/services/app_preferences.dart`, `lib/widgets/keyboard_octave_selector.dart` e `test/keyboard_octave_selector_test.dart`.
- Decisões: seletor limitado a 1–4 oitavas, padrão adaptado ao comportamento anterior (1 em celular, 2 em tela larga), preferência local opcional. A expansão inclui primeiro a oitava acima e depois a abaixo; abaixo de 36 dp por tecla, usa rolagem e posiciona o Dó central na abertura.
- Pendências: testar toque e gesto simultâneo em aparelho físico; o widget test valida quantidade acessível de teclas, limites e persistência da preferência.
- analyze/test: `flutter analyze` sem problemas; `flutter test` passou (47 testes).
