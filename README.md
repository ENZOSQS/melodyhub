# Melody Hub

Aplicativo Flutter de aprendizagem musical com exercícios teóricos e auditivos, gamificação e acompanhamento de progresso. O app usa Firebase Authentication para contas e Cloud Firestore para salvar perfil e histórico.

## Módulo 5 — Histórico e desempenho

- Histórico individual com filtro de período, resultado, pergunta, resposta enviada, resposta correta, XP e duração registrada.
- Relatório semanal com quantidade de exercícios, acertos, precisão geral e diária, XP ganho, tempo de resposta acumulado, distribuição por tipo e itens críticos com pelo menos dois erros.
- Perfil com XP, nível, acertos, erros, precisão, sequência de dias de estudo, sequência de respostas corretas e conquistas.
- Atualização do perfil e criação do evento de histórico na mesma transação do Firestore.

O tempo do relatório é calculado a partir do tempo ativo entre a apresentação de uma pergunta e o envio da resposta. Pausas, tela em segundo plano e uso livre do simulador não são contabilizados. Respostas registradas antes desta medição não têm duração e não entram no total de tempo.

## Conteúdo e progressão

- Questões teóricas distribuídas em cinco níveis, com múltipla escolha e desafios de verdadeiro ou falso.
- Progressão teórica baseada em pelo menos 7 acertos em cada conjunto de 10 respostas.
- Exercício prático de identificação de notas e repetição de sequências, com sequências mais longas nos níveis superiores.
- Exercício auditivo no braço do violão, com amostras de cordas e aceitação de posições que produzam a mesma nota.
- Treino de intervalos auditivos com desafios ascendentes e descendentes; a dificuldade amplia gradualmente os intervalos disponíveis.
- Ditado rítmico com reprodução de padrões e resposta por batidas na tela.
- Simuladores de teclado e braço de violão, com áudio, e preferência de nomenclatura das notas em cifra ou solfejo.
- Lembretes locais de estudo com horário e recorrência em dias selecionados da semana.
- Cada exercício concede pontos; acertos em dificuldades maiores concedem bônus. XP e pontos são saldos separados.
- Loja de ícones com compras salvas no perfil. Ícones também podem ser liberados por conquistas; compras e conquistas são registradas no Firestore.
- Conquistas para progressão, memória auditiva, identificação de intervalos, acúmulo de pontos e coleção de ícones.
- Mapas de fases para teoria, prática e intervalos: fases futuras ficam bloqueadas, as atuais podem ser continuadas e as concluídas podem ser refeitas.
- Loja inicial com dez ícones temáticos de artistas musicais, incluindo imagens dos ícones.

## Dados no Firestore

- `usuarios/{uid}`: perfil, XP, nível, totais e sequências; a preferência `preferencias.nomenclatura` guarda `'cifragem'` ou `'solfejo'` para sincronização entre aparelhos.
- `usuarios/{uid}/historico/{eventoId}`: tipo, resultado, pergunta, resposta enviada e correta, XP, duração em segundos e data. O tipo `'Violão'` identifica os desafios no braço do instrumento; `itemAvaliado` guarda a nota, o intervalo, a categoria teórica ou o tipo de escala/acorde usado no relatório de itens críticos.

O histórico usa horário de servidor para ordenação. A sequência diária usa o dia local do dispositivo no momento do exercício.

## Executar

1. Configure os arquivos de plataforma do Firebase para o projeto.
2. Instale as dependências com `flutter pub get`.
3. Execute com `flutter run` no dispositivo ou emulador desejado.

As credenciais e a configuração do Firebase não devem ser compartilhadas publicamente.

## Regras de segurança

As regras versionadas em `firestore.rules` limitam o acesso ao perfil e ao histórico ao próprio usuário. Para publicá-las no projeto Firebase configurado, execute `firebase deploy --only firestore:rules`.

Foto de perfil fora do escopo: requer Firebase Storage (plano Blaze).

XP e pontos são calculados pelo aplicativo cliente. As regras impedem o acesso aos dados de outras contas e valores negativos nos campos validados, mas não impedem fraude nos próprios dados de uma conta.
