# Melody Hub

Aplicativo Flutter de aprendizagem musical com exercícios teóricos e auditivos, gamificação e acompanhamento de progresso. O app usa Firebase Authentication para contas e Cloud Firestore para salvar perfil e histórico.

## Módulo 5 — Histórico e desempenho

- Histórico individual com filtro de período, resultado, pergunta, resposta enviada, resposta correta, XP e duração registrada.
- Relatório semanal com quantidade de exercícios, acertos, precisão geral e diária, XP ganho, tempo de resposta acumulado e distribuição por tipo.
- Perfil com XP, nível, acertos, erros, precisão, sequência de dias de estudo, sequência de respostas corretas e conquistas.
- Atualização do perfil e criação do evento de histórico na mesma transação do Firestore.

O tempo do relatório é calculado a partir do tempo ativo entre a apresentação de uma pergunta e o envio da resposta. Pausas, tela em segundo plano e uso livre do simulador não são contabilizados. Respostas registradas antes desta medição não têm duração e não entram no total de tempo.

## Dados no Firestore

- `usuarios/{uid}`: perfil, XP, nível, totais e sequências.
- `usuarios/{uid}/historico/{eventoId}`: tipo, resultado, pergunta, resposta enviada e correta, XP, duração em segundos e data.

O histórico usa horário de servidor para ordenação. A sequência diária usa o dia local do dispositivo no momento do exercício.

## Executar

1. Configure os arquivos de plataforma do Firebase para o projeto.
2. Instale as dependências com `flutter pub get`.
3. Execute com `flutter run` no dispositivo ou emulador desejado.

As credenciais e a configuração do Firebase não devem ser compartilhadas publicamente.
