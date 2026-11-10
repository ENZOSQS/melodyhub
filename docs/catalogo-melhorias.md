# Catálogo de melhorias do MelodyHub

## Estado da análise

A inspeção do código encontrou uma base Flutter com exercícios teóricos, identificação de notas, intervalos, teclado, Firebase/Firestore e progressão por níveis. Os problemas de aprendizagem mais visíveis estavam nos próprios fluxos: a prática saltava de uma nota para sequências de até seis; feedback era seguido por avanço automático; o usuário não recebia uma justificativa da resposta; e “Ouvir novamente” no exercício de intervalos sorteava outro par de notas. O banco teórico continha perguntas cuja formulação podia induzir a respostas ambíguas.

## Implementado nesta revisão

| Área | Mudança |
| --- | --- |
| Áudio | Engine SoLoud compartilhada e samples carregados antes do exercício/teclado para reduzir a espera entre ouvir e responder. Notas têm duração de 700 ms e pausa curta de 120 ms nos exercícios. |
| Prática auditiva | Nível 1 começa com uma nota; níveis seguintes crescem gradualmente até cinco notas. A resposta fica visível até a pessoa pedir a próxima questão. Progressão usa 7 acertos em 10 tentativas. |
| Intervalos | Repetir o áudio agora toca o mesmo par. O cronômetro começa depois do som; foi adicionado avanço manual, dica e explicação em semitons e direção. |
| Teoria | Cada questão cadastrada tem uma dica pré-resposta e uma explicação pós-resposta. A pessoa escolhe quando avançar. |
| Conteúdo | Revisadas formulações identificadas como ambíguas ou incorretas, incluindo semitons de Dó a Ré, compasso 6/8, inversões e identificação de acordes. |

## Projetos e bibliotecas consultados

| Projeto | Licença / escopo | Decisão |
| --- | --- | --- |
| [flutter_soloud](https://github.com/alnitak/flutter_soloud) e [documentação do pacote](https://pub.dev/packages/flutter_soloud) | O pacote declara MIT; motor SoLoud com suporte multiplataforma e reprodução de baixa latência. | Adicionado como `flutter_soloud 3.5.4`, compatível com o Dart/Flutter deste app. A versão 3.x requer inicialização e scripts Web incluídos em `web/index.html`. Usado em notas dos exercícios e no teclado, com cache de fontes. |
| [flutter_piano_pro](https://github.com/MelihHakanPektas/flutter_piano_pro) e [API do widget](https://pub.dev/documentation/flutter_piano_pro/latest/index.html) | Widget Flutter MIT, com contagem configurável de notas e eventos de pressionar, arrastar e soltar, inclusive para ponteiros simultâneos. | Adicionado como `flutter_piano_pro 0.6.0` para substituir o teclado artesanal. A tela agora cobre três oitavas, aceita acordes multi-toque e atalhos QWERTY; grava e reproduz o que a pessoa tocou usando o motor SoLoud. |
| [LibrePiano](https://github.com/eagnespuerto/librepiano) | Simulador Web MIT com três oitavas, entrada pelo teclado físico, vozes sintetizadas e visualizador de PDF. | Avaliado; a implementação é HTML/JavaScript isolado, então embutir como WebView criaria um simulador diferente no Web e no app móvel. Usamos o widget Flutter com o mesmo motor de áudio em todas as plataformas. |
| [soundfont_kit](https://pub.dev/packages/soundfont_kit) | MIT; leitura SF2/SF3/SFZ, toque e soltura de vozes polifônicas e reprodução de MIDI. | Avaliado para suporte futuro a instrumentos e arquivos MIDI. O projeto já usa SoLoud, mas o kit requer uma SoundFont com licença de distribuição clara; a tela atual usa os samples já incluídos e grava/reproduz as notas do usuário. |
| [earpath-app](https://github.com/abeage1/earpath-app) | App web de treino auditivo, MIT. Progressão por habilidade e trilhas graduais. | Referência de organização didática; não transplantamos o app web inteiro, porque a interface e o modelo de dados são diferentes. |
| [earwise](https://github.com/abeage1/earwise) | Projeto de treino de intervalos com registro por intervalo e repetição espaçada SM-2. | Referência para uma evolução futura de revisão adaptativa por habilidade. Não foi integrado: precisa de dados de desempenho estáveis e validação didática antes de alterar a progressão. |
| [piano](https://github.com/craigomac/piano) | Widget Flutter de piano e pauta, BSD-3-Clause. | Avaliado, sem adoção: o teclado atual já atende ao simulador; substituir agora mudaria a interface sem resolver o gargalo de áudio/feedback. Reavaliar quando a pauta musical interativa entrar no escopo. |
| [flutter_notemus](https://github.com/alessonqueirozdev-hub/flutter_notemus) | Biblioteca Flutter Apache-2.0 para renderizar pautas e importar/exportar MusicXML/MEI/MIDI. | Candidata para adicionar partitura interativa, ligada ao teclado e aos exercícios. Não integrada agora porque leitura de partitura é uma nova trilha didática, que precisa de exercícios próprios e validação do conteúdo. |
| [ScoreFlow](https://github.com/IlyaSkorik/scoreflow) | Editor de notação Flutter/VexFlow, MIT. | Referência adicional para um futuro módulo de leitura/escrita de partitura. |

## Próximas melhorias recomendadas

| Prioridade | Melhoria | Motivo / próximo passo |
| --- | --- | --- |
| P0 | Versionar e revisar regras do Firestore | Não foi encontrado `firestore.rules` nem configuração de deploy de regras em `firebase.json`. Como o cliente atualiza XP, pontos, compras e progresso, revisar regras no Firebase Console e versioná-las antes de produção. Regras devem validar dono do documento e limitar campos/valores graváveis. |
| P1 | Banco de questões com revisão pedagógica contínua | Cobrir todos os itens com revisão por professor/músico, linguagem consistente e alternativas plausíveis. As explicações atuais são um primeiro suporte de aprendizagem, não substituem validação por especialista. |
| P1 | Repetição espaçada/adaptativa | Registrar erro por intervalo, nota e conceito teórico; agendar revisões curtas dos conceitos que o aluno erra. Definir e validar o algoritmo antes de importar SM-2 sem ajustes para música. |
| P1 | Testes de conteúdo e progressão | O teste existente de login só procura texto sem inicializar o app. Criar testes de unidade para banco (resposta está entre as opções e existe explicação), geração de intervalos e regra 7/10; adicionar testes de widgets para dica/feedback/avanço. |
| P1 | Privacidade e logs | `register_page.dart` imprime UID, nome e e-mail no console. Remover dados pessoais dos logs antes de distribuição. |
| P2 | Separar domínio e armazenamento | `ProgressService` mistura transações, estatísticas e gamificação num serviço extenso. Extrair progresso, conquistas e recompensas para facilitar revisão e testes. |
| P2 | Ajustes de áudio e acessibilidade | Testar latência real em Android, iOS e Web; oferecer controle de velocidade/pausa e volume, teclas de atalho, contraste e suporte a leitor de tela. O comportamento depende do dispositivo e do navegador. |
| P2 | Instalação Web | Atualizar descrição e metadados genéricos “A new Flutter project” no HTML/manifests e verificar ícones, tema e instalação PWA. |

## Referências de desenho didático

As mudanças usam ciclos curtos de tentativa, retorno explicativo e nova tentativa, em vez de esconder a correção ao trocar a questão. A pesquisa sobre prática de recuperação e repetição espaçada sustenta a ideia de revisitar conteúdo ao longo do tempo; a aplicação exata a cada habilidade musical precisa ser avaliada com alunos. Para questões de múltipla escolha, a orientação é formular enunciados claros e distratores plausíveis e homogêneos.

- [Revisão sistemática sobre prática de recuperação e espaçamento (2024)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11078833/)
- [UConn CETL: elaboração de questões de múltipla escolha](https://cetl.uconn.edu/resources/teaching-and-learning-assessment/teaching-and-learning-assessment-overview/assessment-design/developing-multiple-choice-questions/)
- [Flutter cookbook: áudio com SoLoud](https://github.com/flutter/website/blob/main/sites/docs/src/content/cookbook/audio/soloud.md)
- [Licença MIT do pacote flutter_soloud](https://pub.dev/packages/flutter_soloud/license)

## Como avaliar o efeito

Após publicar uma versão de teste, comparar por nível: taxa de acerto na primeira tentativa, abandono, tempo para responder, uso de dica e repetição de áudio. Se acerto subir enquanto abandono cai, manter a progressão; se o aluno acertar só depois de muitas dicas, ajustar conteúdo ou exemplos. Os dados devem ser agregados e não conter áudio ou dados pessoais desnecessários.
