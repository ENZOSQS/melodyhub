# Testes automatizados – Melody Hub

Total: 86 testes (`flutter test`). Última execução: 17/11/2026 – todos aprovados; `flutter analyze` sem problemas.

| Arquivo | O que verifica | Casos |
|---|---|---|
| `test/progress_rules_test.dart` | Regras de gamificação, pontos por estrelas e progresso (RF003, RF007) | 13 |
| `test/study_streak_test.dart` | Sequência de dias de estudo (RF003) | 5 |
| `test/xp_calculator_test.dart` | Cálculo de XP por resposta (RF003) | 2 |
| `test/feedback_rules_test.dart` | Feedback adaptado ao nível do aluno (RF004) | 5 |
| `test/theory_bank_test.dart` | Banco de questões teóricas (RF002) | 3 |
| `test/report_rules_test.dart` | Relatório semanal e itens críticos (RF008, RF009) | 3 |
| `test/continue_rules_test.dart` | Sugestão "Continue de onde parou" (RF012) | 6 |
| `test/reminder_days_test.dart` | Dias dos lembretes de estudo (RF011) | 2 |
| `test/note_names_test.dart` | Nomenclatura das notas (RF010) | 1 |
| `test/sound_assets_test.dart` | Arquivos de áudio empacotados e mapeamento de samples (RF002, RF006) | 4 |
| `test/guitar_fretboard_test.dart` | Altura do braço e posição tocada (widget, RF006) | 2 |
| `test/exercise_catalog_test.dart` | Catálogo de exercícios (widget, RF005) | 1 |
| `test/keyboard_octave_selector_test.dart` | Limites, quantidade de teclas e preferência de oitavas | 1 |
| `test/login_page_test.dart` | Tela de login (widget, RF001) | 2 |
| `test/answer_feedback_rules_test.dart` | Distância, direção, estrelas e acerto por tentativas | 2 |
| `test/ear_training_levels_test.dart` | Progressão de notas e intervalos auditivos | 3 |
| `test/note_identification_rules_test.dart` | Identificar a nota: resolução, níveis, sorteio, resposta e estado dos botões | 20 |
| `test/note_synth_test.dart` | Síntese das notas em PCM: WAV, frequência exata, sem estalo | 4 |
| `test/tempo_rules_test.dart` | Exercício de BPM: tolerância, estrelas e valor inicial | 3 |
| `test/shop_rules_test.dart` | Loja: três faixas de preço e pontos que faltam | 4 |

## Casos de teste

### `test/progress_rules_test.dart`

1. pontos por estrelas não dependem do nível
2. sem estrelas: acerto vale 8 e erro vale 1
3. BPM usa as estrelas calculadas pelo exercício
4. XP e limites de nível do aluno
5. teoria avança com 7/10, não com 6/10 e não passa de 5
6. Prático exige 7/10, conclui etapa e limita o nível em 5
7. Intervalo exige 7/10, conclui etapa e limita o nível em 5
8. habilidade Ritmo progride em habilidadesEtapas
9. habilidade Escala progride em habilidadesEtapas
10. sequência de dias considera mesmo dia, próximo, pausa e mês
11. recupera sequência legada a partir de ultimoExercicio DateTime
12. teoria abaixo do nível atual conclui a etapa sem mudar a rodada atual
13. conquistas solicitadas são concedidas sem duplicação

### `test/study_streak_test.dart`

14. mantém a sequência no mesmo dia do último estudo
15. mantém a sequência enquanto o dia seguinte ainda está em curso
16. zera após um dia completo sem atividade
17. calcula ontem corretamente na virada do mês
18. não mostra sequência sem data ou com saldo zero

### `test/xp_calculator_test.dart`

19. Deve retornar 10 XP quando a resposta estiver correta
20. Deve retornar 0 XP quando a resposta estiver incorreta

### `test/feedback_rules_test.dart`

21. etapas 1 e 2 recebem apoio iniciante
22. etapa 3 recebe apoio intermediário
23. etapas 4 e 5 recebem apoio avançado
24. cinco acertos seguidos elevam o apoio a avançado em qualquer etapa
25. sequência abaixo de cinco mantém o apoio definido pela etapa

### `test/theory_bank_test.dart`

26. cada questão tem resposta única entre as alternativas e nível válido
27. todas as questões incluem dica e explicação específicas
28. banco cobre todos os cinco níveis e mais de um conceito

### `test/report_rules_test.dart`

29. agrupa por tipo e item, conta erros e tentativas, e exige dois erros
30. ignora registros fora da semana e limita os itens aos cinco mais errados
31. conta eventos com horário do servidor à frente do aparelho

### `test/continue_rules_test.dart`

32. sem histórico não há sugestão
33. intervalo mostra a etapa do último exercício
34. etapa fica entre 1 e 5
35. atividades sem trilha não mostram etapa
36. tipo desconhecido é ignorado
37. registros antigos do exercício de acordes são ignorados

### `test/reminder_days_test.dart`

38. dias do lembrete usam semana completa por padrão e persistem ordenados
39. lista inválida vazia mantém o padrão sem deixar lembrete sem dias

### `test/note_names_test.dart`

40. nomeNota aceita classes e MIDI nas duas nomenclaturas

### `test/sound_assets_test.dart`

41. o ditado rítmico possui os três cliques de áudio empacotados
42. o mapa de piano cobre toda a faixa usada e os arquivos existem
43. há sample de violão mapeado para cada corda e casa até a 12ª
44. pitchRatio representa semitons e rejeita deslocamentos maiores

### `test/guitar_fretboard_test.dart`

45. o braço ocupa a altura oferecida em paisagem 800×360
46. toque na quinta corda, casa três, informa MIDI 48

### `test/exercise_catalog_test.dart`

47. filtra por violão e mantém a escolha ao remontar

### `test/keyboard_octave_selector_test.dart`

48. mais e menos ajustam teclas e respeitam os limites 1–4

### `test/login_page_test.dart`

49. mostra e-mail, senha e botão Entrar
50. pede o e-mail quando a recuperação começa sem endereço

### `test/answer_feedback_rules_test.dart`

51. feedback classifica a distância e a direção da nota
52. estrelas e progresso contam até a segunda tentativa

### `test/ear_training_levels_test.dart`

53. identificação de notas cresce conforme os níveis funcionais
54. intervalos começam com saltos grandes e avançam aos menores
55. nota inicial sorteada mantém a chegada dentro da faixa

### `test/note_identification_rules_test.dart`

56. MIDI 60 resolve por [60]
57. MIDI 62 resolve por [62, 60]
58. MIDI 64 resolve por [64, 62, 60]
59. MIDI 65 resolve por [65, 64, 62, 60]
60. MIDI 67 resolve por [67, 69, 71, 72]
61. MIDI 69 resolve por [69, 71, 72]
62. MIDI 71 resolve por [71, 72]
63. notas em oitava grave resolvem à tônica grave correspondente
64. cadência Dó–Fá–Sol–Dó usa acordes maiores em sequência
65. notas disponíveis seguem os cinco níveis
66. item crítico registra a classe de nota com identificador estável
67. acerto é a nota sorteada, em qualquer tentativa
68. erro pede nova tentativa até o 3º, que revela a resposta
69. no nível 5 a mesma nota em outra oitava conta como erro
70. a nota sorteada sempre tem um botão no nível
71. o sorteio alcança todas as notas do nível 5 (duas oitavas)
72. com a questão aberta nenhum botão acende sozinho
73. depois do acerto só a nota sorteada fica verde
74. as notas da resolução não mudam a cor dos botões
75. erros ficam marcados e a revelação mostra a nota sorteada

### `test/note_synth_test.dart`

76. gera WAV PCM 16 bits mono a 44,1 kHz
77. começa e termina em silêncio (sem estalo)
78. soa na frequência exata desde o início, sem deslizar
79. acorde não estoura o limite de 16 bits

### `test/tempo_rules_test.dart`

80. faixa e tolerância de BPM apertam conforme o nível
81. compara o BPM marcado com o original
82. valor inicial do ajuste fica dentro da faixa

### `test/shop_rules_test.dart`

83. três faixas de preço: comum, raro e épico
84. todo ícone à venda segue o preço da sua raridade
85. ícone comum exige de 2 a 3 rodadas de 10 questões bem feitas
86. pontos que faltam e liberação da compra

## Teste manual no celular – `MelodyHub-redesign.apk` (17/11/2026)

**Identificar a nota**

- [ ] A nota soa direto na altura certa, sem "subir" até ela e sem estalo.
- [ ] A cadência Dó–Fá–Sol–Dó soa clara, com uma pausa antes da nota misteriosa.
- [ ] Nenhum botão muda de cor sozinho. Depois do acerto, a resolução aparece só como texto ("Mi → Ré → Dó").
- [ ] O botão verde no fim é sempre a nota que você ouviu, inclusive no nível 5 (duas oitavas).
- [ ] No 3º erro, a resposta certa é revelada.

**Intervalos**

- [ ] "Conheça os sons": o cartão que está tocando mostra o ícone de som.
- [ ] O toque longo numa opção toca aquela opção a partir da mesma nota.
- [ ] No nível 5, intervalos que descem não mostram música de referência.

**Pontos e loja**

- [ ] ★★★ = 10, ★★ = 6, ★ = 3, revelada = 1. Teoria: acerto 8, erro 1.
- [ ] Loja: Comum 150, Raro 400, Épico 900, com "Faltam N pts" e o botão bloqueado até ter pontos.
- [ ] XP e nível do aluno continuam como antes.

**Telas principais e regressão**

- [ ] Perfil sem o controle "BPM inicial"; Desempenho com 4 números.
- [ ] O BPM continua com o mesmo fluxo e com os cliques tocando.
- [ ] O teclado e o violão continuam iguais (samples).
