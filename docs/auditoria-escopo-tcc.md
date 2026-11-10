# Auditoria de funcionalidades do escopo

> Este arquivo preserva fotografias de auditorias feitas em rodadas anteriores. Para a matriz consolidada mais recente, com lacunas e validações desta revisão, consulte [`relatorio-revisao-funcional-2026-11-10.md`](relatorio-revisao-funcional-2026-11-10.md).

Referência: documento de projeto, capítulos 1 e 2, em especial objetivos, critérios de aceitação, requisitos funcionais e casos de uso.

## Cobertura encontrada

| Requisito do projeto | Situação no aplicativo | Evidência / observação |
| --- | --- | --- |
| Cadastro, login e sessão | Implementado | Firebase Authentication; o estado de autenticação decide entre login e tela inicial. |
| Persistência de perfil e progresso na nuvem | Implementado | Cloud Firestore guarda progresso e histórico por usuário. |
| Exercícios auditivos com notas | Implementado | O modo prático toca uma nota ou uma sequência, recebe as notas tocadas no teclado e registra a resposta. |
| Intervalos melódicos | Implementado parcialmente | Toca pares de notas e oferece feedback por alternativa. O usuário não identifica o intervalo tocando no instrumento, como o caso de uso específico descreve. |
| Escalas e acordes | Implementado parcialmente | Há questões teóricas sobre esses conteúdos, mas não há uma atividade auditiva dedicada a executar ou reconhecer escalas e acordes. |
| Ditado rítmico | Não implementado | Não existe exercício de sequência rítmica reproduzida por batidas ou teclado. |
| Validação e feedback pedagógico | Implementado | Teoria, prática e intervalos apresentam resultado; erros podem abrir dicas ou explicações. |
| Trilha progressiva e níveis | Implementado | Trilhas de teoria, prática e intervalos guardam nível, tentativas e desbloqueios. |
| Pontos, XP e conquistas | Implementado | O progresso do exercício atualiza pontos, XP, níveis e conquistas no Firestore. |
| Sequência de dias de estudo | Corrigido nesta revisão | O valor agora depende da última data de estudo, zera após um dia completo sem atividade, é persistido ao abrir o app e reavaliado na virada do dia. |
| Simulador musical | Implementado parcialmente | Há teclado virtual tocável, com gravação e reprodução de notas. Não há simulador de braço de violão. |
| Explorar e filtrar exercícios | Implementado parcialmente | A pessoa escolhe trilhas e fases; não há catálogo com busca/filtros por tema ou instrumento. |
| Histórico de exercícios | Implementado | Exibe respostas, resultado, data, XP e duração registrados. |
| Relatório de desempenho | Implementado parcialmente | Há um resumo semanal com volume, precisão, XP, tempo e categorias; não há recomendação automática de pontos fracos nem entrega agendada. |
| Personalização do perfil | Implementado parcialmente | Permite nome e ícone; foto e preferências de exibição descritas no documento não aparecem como configurações do perfil. |
| Notificações e lembretes | Não implementado | Não foram encontrados fluxo de agendamento, permissão ou notificações locais/push. |
| Administração de usuários e exercícios | Não implementado | Não há painel ou fluxo administrativo para configurar atividades e acompanhar usuários. |
| Portabilidade mobile | Prevista na base Flutter | O projeto possui targets móveis, mas esta revisão não validou instalação e interação em dispositivos físicos Android/iOS. |
| Baixa latência de áudio | Parcial, sem medição de hardware | A reprodução do exercício foi encurtada e possui opção lenta; latência real precisa ser medida em aparelhos. |

## Regra da sequência diária

Uma atividade conta no dia local do dispositivo. O contador permanece disponível durante o dia seguinte para que o aluno possa continuar a sequência. Se esse dia também terminar sem atividade, a sequência atual passa a zero; o recorde histórico permanece intacto. Ao estudar novamente, uma nova sequência começa em um dia.

## Verificação realizada

- Revisão estática das telas, serviços e dependências relacionadas aos requisitos.
- Testes unitários da regra de sequência: mesmo dia, dia seguinte, dia perdido, virada de mês e ausência de data.
- `flutter test` passou após a alteração.
- `flutter analyze` passou sem apontar problemas após a limpeza dos avisos encontrados.
- O build Windows Release compilou e abriu com a sessão autenticada; a sequência vencida foi exibida como zero e reconciliada no perfil.
- Áudio, multitouch e layout ainda não foram exercitados em aparelhos físicos Android/iOS.

## Revisão após a implementação desta rodada

| Requisito | Estado revisto | Resultado e limite |
| --- | --- | --- |
| Questões teóricas | Coberto e verificado | 65 questões em cinco níveis, cada uma com alternativas, resposta, dica e explicação específica; teste automatizado verifica IDs, respostas, duplicatas e cobertura de explicação. |
| Ditado rítmico | Implementado | Cinco etapas, BPM ajustável, contagem de quatro pulsos, reprodução em subdivisões, captura de toque e feedback de erro médio; registrado em histórico/progresso. |
| Escalas e acordes | Implementado | Atividades auditivas dedicadas, com famílias progressivas, reprodução repetível, dicas e explicações por semitons; progresso separado por habilidade. |
| Braço de violão | Implementado | Mapa de seis cordas, afinação padrão, 13 casas e reprodução das notas por sample transposto. |
| Catálogo | Implementado | Busca textual e filtros por habilidade, nível e instrumento; atividades abrem suas rotas existentes. |
| Preferências de perfil | Implementado | Cifragem/solfejo, rótulos do teclado, BPM padrão e lembrete local opt-in. |
| Foto do perfil | Implementado com dependência externa | Seleção e envio para Firebase Storage; a confirmação falha de forma visível quando o bucket ou regras por usuário não permitem upload. |
| Relatório | Melhorado | Resultado semanal agora agrega categorias e recomenda uma rota de revisão quando há pelo menos três tentativas e precisão de até 70%. |
| Notificações | Implementadas com dependência da plataforma | Lembrete diário, permissão solicitada ao ativar, reagendamento/cancelamento e aviso de conquista. Não foi validado após reinicialização em aparelho físico. |
| Acesso administrativo | Pendente de infraestrutura segura | O app não deve consultar ou alterar dados de todas as contas somente com controles na interface. Falta definir custom claims, regras Firestore/Storage e/ou backend confiável, testar no Emulator e provisionar o administrador. |
| Áudio e layout mobile | Parcialmente verificado | O APK compila nesta etapa; latência, toque simultâneo, orientação, volume e notificações precisam de validação em aparelhos reais. |

## Verificação desta rodada

- `flutter analyze`: sem problemas.
- `flutter test`: todas as suítes passaram, incluindo sequência de estudo, XP e banco teórico.
- `flutter build apk --debug`: concluído.
- `flutter build apk --release --target-platform android-arm64`: concluído; APK otimizado para celulares ARM64 em `build/app/outputs/flutter-apk/app-release.apk` (43,8 MB). A configuração atual assina com chave Debug, então serve para instalação/teste e precisa de assinatura de produção antes de publicação em loja.
- `flutter build web`: concluído em `build/web`.
- `git diff --check`: sem erros de whitespace; Git avisou somente sobre conversão LF/CRLF em arquivos Flutter gerados e existentes.

## Pendente para concluir cobertura integral

1. Preparar e revisar um desenho administrativo com autorização por custom claim e políticas Firestore/Storage; testar em Emulator e só então publicar regras por processo autorizado.
2. Confirmar que Firebase Storage está habilitado e aplicar regras que limitem cada foto ao próprio usuário.
3. Testar latência, multitouch, layout do teclado/violão e lembretes em celulares Android/iOS reais.
4. Revisar a distribuição didática com alunos/orientador e ajustar os limiares de avanço conforme uso real.

## Correções de organização e áudio — 10/11/2026

- O catálogo **Explorar atividades** agora lista atividades de aprendizagem, incluindo acordes e escalas. Os simuladores foram retirados desse catálogo.
- A tela principal oferece **Simuladores de instrumentos**, com destinos separados para o teclado e o braço do violão.
- O braço de violão usa 78 samples OGG reais de nylon, mapeados por corda e casa (afinação padrão, trastes 0–12). Os arquivos vêm da coleção Meta Nylon Guitar, licença CC0 1.0; a licença e a origem estão junto dos assets.
- O ditado rítmico tentava carregar `C5.wav`, que não existia nos assets; por isso o próprio exercício mostrava que não conseguia reproduzir. Agora usa três cliques WAV gerados para este aplicativo: tempo forte, pulso e evento rítmico.
- A identidade visual foi aquecida com carvão ameixa, dourado champanhe e rosé, substituindo a paleta azul e turquesa. Gradientes de superfície e a transição suave entre telas seguem o mesmo conjunto de cores.
- Verificação: `flutter analyze` e `flutter test` concluíram sem erros. O teste novo confirma os três sons do ritmo e valida no pacote todos os 78 samples do braço. O áudio ainda depende de teste auditivo em aparelho físico antes de se afirmar qualidade e volume em todas as plataformas.

## Revisão funcional e interação musical — 10/11/2026

- A navegação principal passou a manter quatro destinos visíveis, com barra inferior em telas abaixo de 600 dp e trilho lateral em telas maiores; a página inicial também organiza trilhas em cartões de grade.
- A atividade de intervalos agora pede que o aluno reproduza a nota de chegada no teclado. O modo normal passou de 420 ms + 85 ms entre notas para 300 ms + 55 ms; o modo lento permanece disponível.
- A atividade de acordes compara a tríade que o aluno toca no piano às notas geradas para a questão. O botão de repetição das atividades de escala/acorde conserva a resposta sorteada.
- O braço de violão agora é desenhado com aspecto de instrumento (madeira, seis cordas, trastes proporcionais e marcadores); toque e arraste em corda/casa disparam o sample correspondente. Um controle opcional mostra os nomes das notas.
- Relatório completo, matriz funcional e pendências estão em `docs/relatorio-revisao-funcional-2026-11-10.md`. Permanecem lacunas de filtro por instrumento, definição administrativa e medições em aparelhos físicos.
- Verificação desta rodada: `flutter analyze` limpo, 12 testes passaram e auditoria automatizada do banco teórico conferiu 65 questões em cinco níveis. `flutter build apk --release --target-platform android-arm64` compilou em `build/app/outputs/flutter-apk/app-release.apk` (47,9 MB), assinado com a chave de depuração atual; para publicação em loja deve ser configurada uma chave de produção.
