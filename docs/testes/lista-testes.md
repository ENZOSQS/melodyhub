# Testes automatizados – Melody Hub

Total: 51 testes (`flutter test`). Última execução: 12/11/2026 – todos aprovados; `flutter analyze` sem problemas.

| Arquivo | O que verifica | Casos |
|---|---|---|
| `test/progress_rules_test.dart` | Regras de gamificação e progresso (RF003, RF007) | 11 |
| `test/study_streak_test.dart` | Sequência de dias de estudo (RF003) | 5 |
| `test/xp_calculator_test.dart` | Cálculo de XP por resposta (RF003) | 2 |
| `test/feedback_rules_test.dart` | Feedback adaptado ao nível do aluno (RF004) | 5 |
| `test/theory_bank_test.dart` | Banco de questões teóricas (RF002) | 3 |
| `test/report_rules_test.dart` | Relatório semanal e itens críticos (RF008, RF009) | 3 |
| `test/continue_rules_test.dart` | Sugestão "Continue de onde parou" (RF012) | 5 |
| `test/reminder_days_test.dart` | Dias dos lembretes de estudo (RF011) | 2 |
| `test/note_names_test.dart` | Nomenclatura das notas (RF010) | 1 |
| `test/sound_assets_test.dart` | Arquivos de áudio empacotados e mapeamento de samples (RF002, RF006) | 4 |
| `test/guitar_fretboard_test.dart` | Altura do braço e posição tocada (widget, RF006) | 2 |
| `test/exercise_catalog_test.dart` | Catálogo de exercícios (widget, RF005) | 1 |
| `test/keyboard_octave_selector_test.dart` | Limites, quantidade de teclas e preferência de oitavas | 1 |
| `test/login_page_test.dart` | Tela de login (widget, RF001) | 2 |
| `test/answer_feedback_rules_test.dart` | Distância, direção, estrelas e acerto por tentativas | 2 |
| `test/ear_training_levels_test.dart` | Progressão de notas e intervalos auditivos | 2 |

## Casos de teste

### `test/progress_rules_test.dart`

1. XP, pontos e limites de nível
2. teoria avança com 7/10, não com 6/10 e não passa de 5
3. Prático exige 7/10, conclui etapa e limita o nível em 5
4. Intervalo exige 7/10, conclui etapa e limita o nível em 5
5. habilidade Ritmo progride em habilidadesEtapas
6. habilidade Escala progride em habilidadesEtapas
7. habilidade Acorde progride em habilidadesEtapas
8. sequência de dias considera mesmo dia, próximo, pausa e mês
9. recupera sequência legada a partir de ultimoExercicio DateTime
10. teoria abaixo do nível atual conclui a etapa sem mudar a rodada atual
11. conquistas solicitadas são concedidas sem duplicação

### `test/study_streak_test.dart`

12. mantém a sequência no mesmo dia do último estudo
13. mantém a sequência enquanto o dia seguinte ainda está em curso
14. zera após um dia completo sem atividade
15. calcula ontem corretamente na virada do mês
16. não mostra sequência sem data ou com saldo zero

### `test/xp_calculator_test.dart`

17. Deve retornar 10 XP quando a resposta estiver correta
18. Deve retornar 0 XP quando a resposta estiver incorreta

### `test/feedback_rules_test.dart`

19. etapas 1 e 2 recebem apoio iniciante
20. etapa 3 recebe apoio intermediário
21. etapas 4 e 5 recebem apoio avançado
22. cinco acertos seguidos elevam o apoio a avançado em qualquer etapa
23. sequência abaixo de cinco mantém o apoio definido pela etapa

### `test/theory_bank_test.dart`

24. cada questão tem resposta única entre as alternativas e nível válido
25. todas as questões incluem dica e explicação específicas
26. banco cobre todos os cinco níveis e mais de um conceito

### `test/report_rules_test.dart`

27. agrupa por tipo e item, conta erros e tentativas, e exige dois erros
28. ignora registros fora da semana e limita os itens aos cinco mais errados
29. conta eventos com horário do servidor à frente do aparelho

### `test/continue_rules_test.dart`

30. sem histórico não há sugestão
31. intervalo mostra a etapa do último exercício
32. etapa fica entre 1 e 5
33. atividades sem trilha não mostram etapa
34. tipo desconhecido é ignorado

### `test/reminder_days_test.dart`

35. dias do lembrete usam semana completa por padrão e persistem ordenados
36. lista inválida vazia mantém o padrão sem deixar lembrete sem dias

### `test/note_names_test.dart`

37. nomeNota aceita classes e MIDI nas duas nomenclaturas

### `test/sound_assets_test.dart`

38. o ditado rítmico possui os três cliques de áudio empacotados
39. o mapa de piano cobre toda a faixa usada e os arquivos existem
40. há sample de violão para cada corda e casa do simulador
41. pitchRatio representa semitons e rejeita deslocamentos maiores

### `test/guitar_fretboard_test.dart`

42. o braço ocupa a altura oferecida em paisagem 800×360
43. toque na quinta corda, casa três, informa MIDI 48

### `test/exercise_catalog_test.dart`

44. filtra por violão e mantém a escolha ao remontar

### `test/keyboard_octave_selector_test.dart`

45. ajusta teclas brancas e respeita os limites de 1–4 oitavas

### `test/login_page_test.dart`

46. mostra e-mail, senha e botão Entrar
47. pede o e-mail quando a recuperação começa sem endereço

### `test/answer_feedback_rules_test.dart`

48. classifica distância e direção da nota
49. estrelas e progresso contam até a segunda tentativa

### `test/ear_training_levels_test.dart`

50. prática de notas cresce em complexidade e tamanho
51. intervalos começam com saltos grandes e avançam aos menores

