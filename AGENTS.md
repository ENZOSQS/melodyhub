# AGENTS.md — Melody Hub

Instruções para agentes de código (Codex e outros) que trabalham neste repositório.

## O projeto

Melody Hub é o aplicativo do TCC "Desenvolvimento de aplicativo móvel para ensino de música"
(Engenharia de Software, UNIGRAN). É feito em Flutter/Dart, com Firebase Auth, Cloud Firestore
e Firebase Storage. Áudio: `flutter_soloud`. Teclado livre: `flutter_piano_pro`.

## Estrutura

- `lib/main.dart`: inicialização e `AuthGate`, que alterna entre login e `AppShell`.
- `lib/screens/`: telas. A lógica de cada exercício fica na própria tela.
- `lib/services/`: `progress_service.dart` (progresso, histórico, conquistas, loja),
  `music_audio_service.dart`, `app_preferences.dart` (SharedPreferences) e `reminder_service.dart`.
- `lib/utils/`, `lib/widgets/` e `lib/data/` (banco de questões e ícones).
- `test/`: testes unitários. `docs/`: relatórios de revisão e as tarefas (`docs/tarefas-codex.md`).
- Firestore: `usuarios/{uid}` (perfil e progresso) e `usuarios/{uid}/historico/{eventoId}`.

## Regras de trabalho

1. Faça **uma tarefa por vez**, na ordem de `docs/tarefas-codex.md`, salvo pedido diferente.
2. Mexa só no que a tarefa pede. Não reformate arquivos inteiros, não renomeie o que
   não foi pedido e não troque dependências sem necessidade.
3. Interface, mensagens e nomes de domínio ficam em **português**, seguindo o código existente
   (`registrarExercicio`, `acertou`, `nivelTeoria`...).
4. Não altere o formato dos dados já gravados no Firestore de um jeito que quebre contas
   existentes. Campos novos precisam ser opcionais e ter um valor padrão na leitura.
5. Não publique regras nem faça deploy no Firebase. Não altere `firebase_options.dart`
   nem `google-services.json`.
6. Antes de dar uma tarefa por concluída, rode e deixe passando:
   - `flutter analyze` (sem problemas novos)
   - `flutter test`
7. Faça **um commit por tarefa**, com a mensagem `tarefa N: <resumo>`.
8. Ao terminar cada tarefa, preencha o bloco "Registro" dela em `docs/tarefas-codex.md`:
   arquivos alterados, decisões tomadas, o que ficou pendente e o resultado de
   `flutter analyze` e `flutter test`. Esse registro é usado na revisão.
9. Se algo da tarefa estiver ambíguo ou impossível, escolha a solução mais simples,
   registre a decisão no "Registro" e siga em frente.
10. Não edite o documento do TCC (.docx), nem os arquivos `docs/auditoria-*.md` e
    `docs/relatorio-*.md`.
