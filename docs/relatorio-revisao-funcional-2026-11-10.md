# Relatório de revisão funcional e didática — Melody Hub

**Data da revisão:** 10/11/2026  
**Base documental:** PDF do TCC, requisitos do sistema e casos de uso, seções 2.2–2.4 (páginas 15–29 da extração disponível).  
**Escopo desta rodada:** identidade e navegação principal, simulador de braço de violão, respostas musicais pelo teclado, reprodução de intervalos e revisão dos módulos contra o TCC.

## Síntese

Os seis requisitos funcionais centrais da seção 2.2 estão cobertos no código atual. Esta rodada também aproximou a resposta dos exercícios ao fluxo descrito nos casos de uso: intervalos são respondidos tocando a nota de chegada no teclado, e acordes são montados tocando três notas. O braço de violão foi reconstruído como desenho vetorial interativo, sem células semelhantes a teclas.

Isso não equivale a aceite integral do sistema em contexto de uso: há requisitos detalhados ainda parciais, a autorização administrativa não tem especificação de segurança completa e latência/usabilidade precisam ser medidas em celulares. A tabela abaixo separa implementação no código de validações que dependem de infraestrutura ou usuários.

## Catálogo de referências consultadas

- [Flutter — abordagem para interfaces adaptáveis](https://docs.flutter.dev/ui/adaptive-responsive/general): orienta medir o espaço real com `LayoutBuilder` e alternar barra inferior em janelas compactas e `NavigationRail` em janelas a partir de 600 dp. Aplicado no shell de navegação.
- [FretFlow — fretboard interativo no GitHub](https://github.com/Lfrangt/fretflow-ui): referência para explorar posições tocáveis, restringir a área de casas e ouvir posições. A implementação foi refeita em Flutter/Dart com `CustomPainter`; o código React desse repositório não foi copiado.
- [Intervals — treino auditivo no GitHub](https://github.com/dffmonolith/intervals): oferece progressão de treino, repetição do trecho, pistas com músicas familiares, direção melódica e estatísticas. Nesta rodada foram adotados resposta ativa no instrumento, repetição, dica e explicação após erro; microfone e estatísticas por intervalo permanecem fora deste escopo.
- [Ear Training — intervalos, acordes e escalas no GitHub](https://github.com/berruezo/ear-training): referência de separar habilidades auditivas e limitar o conjunto de respostas por etapa. Usado como comparação de organização; não foi incorporado código.
- [Meta Open Sound](https://github.com/facebookincubator/Meta-open-sound): origem dos samples de violão de nylon já incluídos em `assets/sounds/guitar/`; a cópia local registra a licença CC0 junto aos arquivos.

## Requisitos funcionais gerais (seção 2.2)

| Requisito | Estado | Evidência e limite conhecido |
| --- | --- | --- |
| Cadastro, login e salvamento do progresso na nuvem | **Implementado** | Firebase Authentication nos fluxos de cadastro/login; Firestore por usuário no serviço de progresso e histórico. A gravação exige rede, como define o requisito não funcional. |
| Reproduzir frequências/notas para identificação de intervalos e acordes | **Implementado** | Prática reproduz notas e sequências; intervalos toca pares; escalas e acordes reproduzem os sons. Acordes agora recebem a resposta montada em três notas no piano virtual. |
| XP, sequência de dias e níveis | **Implementado** | Atualização de XP, proficiência, tentativas, desbloqueios e conquistas vinculada ao registro de atividade. A sequência diária é recalculada com base na última data de estudo. |
| Validar respostas e explicar acertos/erros | **Implementado** | Teoria tem dicas e explicações por questão; prática e intervalos registram resposta e feedback; escalas/acordes exibem explicação da estrutura; ritmo informa erro temporal médio. |
| Árvore/trilha de habilidades com desbloqueio por progresso | **Implementado** | Trilhas de teoria, prática e intervalos e etapas específicas de ritmo, escalas e acordes consultam progresso e limitam níveis liberados. |
| Simuladores de teclado e braço de violão | **Implementado** | Teclado virtual livre; braço vetorial com seis cordas, casas 0–12, padrão de afinação E–A–D–G–B–E, amostra própria por corda/casa e resposta a toque/arraste. |

## Requisitos não funcionais e evidências

| Requisito | Estado | Evidência e limite conhecido |
| --- | --- | --- |
| Flutter com portabilidade Android/iOS | **Implementado na base; validação parcial** | Projeto Flutter; APK Android de depuração compilado. Não foi possível validar instalação, rotação e toque em aparelhos iOS/Android físicos nesta rodada. |
| Interface fluida e acessível | **Parcial** | Shell usa destinos persistentes, transição curta e layout adaptável (`NavigationBar` abaixo de 600 dp; `NavigationRail` a partir de 600 dp). Ainda falta auditoria formal de leitor de tela, contraste e navegação por teclado/controle assistivo. |
| Minimizar latência de áudio | **Parcial, sem medição física** | Samples são pré-carregados pelo serviço SoLoud. Intervalos e prática agora usam notas de 300 ms e pausa de 55 ms no modo normal, com opção lenta. Esses tempos são do padrão de reprodução e não medem a latência toque→som do aparelho. |
| Internet necessária para sincronização | **Implementado** | Progresso e perfil estão integrados ao Firebase. A operação sem rede não foi especificada como requisito e não foi prometido funcionamento offline de sincronização. |

## Casos de uso (seções 2.3–2.4)

| Caso descrito no TCC | Estado | Revisão do fluxo |
| --- | --- | --- |
| Gerenciar usuário: cadastrar, autenticar e manter sessão | **Implementado** | Cadastro, login por e-mail/senha, observação do estado de autenticação e restauração de sessão pelo Firebase. |
| Consultar evolução (perfil, histórico, XP e medalhas) | **Implementado** | Perfil, histórico paginado, conquistas e desempenho usam dados da conta autenticada. |
| Realizar exercício auditivo | **Implementado** | O aluno escuta o desafio, responde por interação musical quando aplicável, recebe retorno e registra a tentativa. |
| Identificar notas | **Implementado** | Prática de memória auditiva recebe notas tocadas no teclado virtual e valida a sequência em ordem. |
| Identificar intervalos melódicos | **Implementado nesta rodada** | Toca duas notas; o aluno reproduz a nota final no teclado. A validação compara a nota tocada com a chegada do intervalo e o progresso guarda a resposta. A tela informa a nota inicial e oferece dica/explicação. |
| Ditado rítmico simples | **Implementado** | Reproduz padrão com contagem/BPM, recebe batidas por toque e calcula erro temporal; feedback oferece orientação de pulso/contratempo. Os sons necessários estão empacotados. |
| Explorar por tipo, nível ou tema | **Implementado parcialmente** | Catálogo possui busca, categoria/habilidade e nível, com rotas funcionais. |
| Filtrar a lista por teclado ou violão | **Pendente** | O caso específico pede filtro de instrumento e manutenção da preferência. O catálogo ainda não tem esse filtro; os simuladores ficam na seção própria para manter a organização atual da navegação. |
| Ver histórico detalhado e estatísticas de erros | **Parcial** | Histórico registra tipo, pergunta, resposta, gabarito, data e duração; desempenho resume categorias e sugere revisão. Ainda não há visão sistemática de cada erro por nota/intervalo nem exportação definida pelo TCC. |
| Personalizar perfil e preferências | **Parcial** | Edição de nome, imagem (condicionada ao Firebase Storage), cifras/solfejo, rótulos do teclado, BPM e lembrete. A configuração de afinação por instrumento descrita no caso específico não está implementada; a afinação do violão permanece padrão. |
| Relatório semanal personalizado | **Implementado parcialmente** | A tela de desempenho apresenta agregados recentes, gráfico semanal e sugestões acionáveis quando há dados suficientes. A geração é acessada manualmente; não há entrega semanal agendada. |
| Lembrete de estudo e notificação de conquista | **Parcial** | Lembrete diário local configurável por horário e aviso local de conquista têm integração. O usuário não escolhe dias da semana e não há envio push remoto. Permissões e funcionamento após reinicialização dependem de validação no aparelho. |
| Administração (ator citado no documento) | **Pendente de definição/infraestrutura segura** | Não existe painel administrativo. O TCC não detalha operações ou política de autorização o suficiente para habilitar consulta de todos os perfis; qualquer painel exige autorização confiável no servidor, custom claims/regras e teste de segurança.

## Revisão por módulo do aplicativo

| Módulo | Estado nesta revisão | Resultado e ação realizada |
| --- | --- | --- |
| Autenticação e cadastro | Conforme | Firebase Auth e redirecionamento baseado na sessão autenticada. |
| Início e navegação | Melhorado | Ações principais da página inicial foram reorganizadas em cartões de aprendizagem; navegação persistente agora oferece Início, Aprender, Tocar e Progresso, com barra inferior em telas estreitas, trilho lateral em telas largas e transição animada. |
| Catálogo de atividades | Parcial | Busca, categorias e níveis funcionam; filtro de instrumento é lacuna conhecida e fica explicitado acima. |
| Trilha teórica e banco de perguntas | Conforme no código revisado | 65 perguntas nos cinco níveis; todas têm dica/explicação associada e resposta presente nas alternativas. Auditoria automatizada conferiu IDs únicos, opções sem duplicata, nível e cobertura. Revisão semântica amostral confirmou conceitos básicos, tonalidades, intervalos, acordes, escalas, ritmo e forma musical; recomenda-se revisão final pelo orientador/músico.
| Trilha prática de notas | Conforme | Repetição de sequência, captura ordenada por teclado, feedback em erro e registro de progresso. Ritmo normal foi reduzido de 420 ms + 85 ms para 300 ms + 55 ms entre notas; a opção lenta foi mantida.
| Intervalos | Melhorado | Substituídas alternativas textuais pela reprodução da nota de chegada num teclado responsivo; repetição, controle de velocidade, dica, explicação e avanço de fase foram preservados. Ritmo normal também passou para 300 ms + 55 ms.
| Escalas | Conforme com resposta teórica | Mantém audição repetível, etapas graduais, alternativas, dica e explicação em semitons. Não requer montar a sequência completa no teclado nesta versão.
| Acordes | Melhorado | Agora o aluno monta a tríade tocando três notas no piano virtual; as alturas são comparadas com os intervalos da qualidade sorteada. Há indicação da fundamental, possibilidade de limpar seleção e explicação posterior.
| Ritmo | Conforme | Ditado funcional com contagem, BPM, pulso animado, captura de batidas, tolerância e medida de erro. Requer teste auditivo/tátil em dispositivo para aferir latência real.
| Simulador de teclado | Conforme no código | Mantém interação de múltiplas teclas, sustentação/release e reprodução/gravação existentes. Interação multitouch e resposta de áudio não foram medidas em aparelho físico nesta rodada.
| Simulador de braço do violão | Melhorado | Substituída a grade de células por braço desenhado: madeira, nut, espaçamento temperado dos trastes, marcadores, seis cordas metálicas em calibres distintos e nome das cordas. Toque e arraste disparam samples; botão “Ver notas” revela o mapa sem tornar o instrumento uma fileira de botões.
| Perfil, lembretes e preferências | Parcial | Preferências locais e agendamento local existentes. Foto requer Firebase Storage e regras do bucket; lembrete requer permissão e teste do ciclo de vida no dispositivo.
| Histórico, relatório, XP e conquistas | Conforme com limites | Registros e agregados estão acessíveis; relatório recomenda conteúdos quando há amostra mínima. Administração/observabilidade global de alunos ainda não existe.

## Implementações desta rodada

1. Criado `lib/screens/app_shell.dart` com `NavigationBar` e `NavigationRail`, seleção persistente e animação curta entre destinos. O breakpoint de 600 dp segue a recomendação de layout adaptável da documentação Flutter.
2. Cartões da página inicial agora organizam as trilhas em uma grade visual em vez de uma lista vertical de links idênticos.
3. Criado `lib/widgets/piano_answer_keyboard.dart`, um teclado de uma oitava com teclas brancas/pretas e resposta tátil.
4. Intervalos passaram a aceitar resposta tocada no piano; prática e intervalos têm reprodução normal mais rápida, mantendo modo lento.
5. Acordes passaram a exigir a montagem de uma tríade no piano. Corrigida também a repetição do áudio em escalas/acordes: repetir não apaga mais a resposta sorteada.
6. `lib/screens/guitar_fretboard_screen.dart` foi redesenhado como fretboard de toque/arraste em `CustomPainter`; os samples CC0 continuam associados à corda e à casa correspondentes.

## Verificações executadas

- `flutter analyze`: **sem problemas**.
- `flutter test`: **12 testes passaram**, incluindo banco teórico, sequência diária, cálculo de XP e presença dos sons/samples.
- `python tmp/audit_question_bank.py`: **65 questões**, 17 categorias; não encontrou resposta fora das alternativas, questão sem dica/explicação, IDs duplicados ou falta de alternativas.
- `flutter build apk --release --target-platform android-arm64`: **concluído** em `build/app/outputs/flutter-apk/app-release.apk` (47,9 MB), incluindo as alterações desta rodada. A variante Release está assinada com a chave de depuração pela configuração atual do Gradle; serve para instalar/avaliar em aparelhos ARM64, mas precisa de chave de produção para distribuição em loja.
- `flutter build apk --debug`: também compilou; artefato de desenvolvimento em `build/app/outputs/flutter-apk/app-debug.apk`.
- A compilação não valida som, multitouch, orientação, permissões ou legibilidade em aparelho físico. Esses itens continuam como aceite manual.

## Pendências ordenadas

1. Implementar filtro por instrumento no catálogo com conteúdo executável para teclado e violão, e persistir a seleção; definir quais exercícios realmente aceitam cada instrumento antes de exibir filtros que não correspondam a uma rota funcional.
2. Completar as preferências de afinação no simulador e no perfil, se o orientador confirmar que “afinação” significa ajustar as cordas do instrumento e não apenas o sistema de rótulos.
3. Definir se notificações do TCC devem ser locais ou push; a versão atual implementa somente local, com lembrete diário sem seleção de dias.
4. Especificar o papel administrativo e implementar acesso no servidor (claims/regras/functions) antes de criar uma interface de administração.
5. Medir latência e validar áudio, multitouch, gestos do fretboard, acessibilidade e notificações em celulares Android/iOS; estes não podem ser concluídos por build ou testes unitários no desktop.
6. Fazer aceite pedagógico com o orientador e iniciantes: dificuldade, linguagem, limiar de avanço (7 acertos em 10) e clareza das dicas devem ser avaliados com dados de uso.

## Fontes do projeto e externas

- Requisitos e casos de uso extraídos do PDF do TCC: `tmp/tcc-current-requirements.txt` (páginas 15–29).
- Auditoria anterior e plano de ação: `docs/auditoria-escopo-tcc.md` e `docs/plano-acao-escopo.md`.
- Documentação Flutter sobre adaptação de layout: <https://docs.flutter.dev/ui/adaptive-responsive/general>.
- Repositórios de referência: <https://github.com/Lfrangt/fretflow-ui>, <https://github.com/dffmonolith/intervals>, <https://github.com/berruezo/ear-training>, <https://github.com/facebookincubator/Meta-open-sound>.
