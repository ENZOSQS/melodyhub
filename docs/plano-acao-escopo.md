# Plano de ação para cobrir o escopo do TCC

## Critério de execução

Cada requisito será marcado como entregue somente quando houver caminho acessível na interface, dados persistidos quando necessário e uma verificação automatizada ou manual registrada. Recursos que exigem autorização/infraestrutura externa (Storage, permissões de notificação, regras de administrador) terão tratamento de indisponibilidade e instruções de configuração; o app não deve fingir sucesso quando o serviço não está configurado.

## Referências de desenho consultadas

- [earpath](https://github.com/abeage1/earpath-app): currículo incremental, objetivos pequenos por nível, revisão e variedade de treino auditivo. Adotar como inspiração pedagógica, sem copiar o projeto.
- [ear-training](https://github.com/berruezo/ear-training): separação por exercícios de intervalos, acordes e escalas, mais modos livre, cronometrado e sequência.
- [MyPitch](https://github.com/saverinonrails/mypitch): contexto tonal, graus da escala, acorde e relatório de pontos fortes/fracos.
- [TempoDeck](https://github.com/marcelgast/tempodeck): controle explícito de BPM, subdivisão, acentos e configuração persistente de prática rítmica.
- [ChordMaster-Free](https://github.com/BrianZamacona/ChordMaster-Free): combinação de treino auditivo e desafios rítmicos numa aplicação Flutter.
- [Meta Open Sound](https://github.com/facebookincubator/Meta-open-sound): samples multisampleados de violão nylon; os instrumentos da coleção são CC0 e incluem mapa de notas por corda.
- [flutter_soloud](https://github.com/alnitak/flutter_soloud): playback de baixo atraso e suporte a OGG/WAV, adequado para disparar notas e pulsos do exercício.
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications): lembretes locais sob controle do usuário, com pedido de permissão no contexto de ativação.
- [Firebase Storage para Flutter](https://pub.dev/packages/firebase_storage): armazenamento de imagem de perfil associado à conta, condicionado a regras do Storage.

Essas fontes servem para comparar padrões e recursos; não implicam portabilidade irrestrita do código dos projetos citados.

## Matriz de execução

| Etapa | Requisito / lacuna | Implementação planejada | Critério de conclusão |
| --- | --- | --- | --- |
| 1 | Explorar exercícios | Catálogo único com busca, filtros por habilidade, nível e instrumento, e persistência da preferência | Cada card abre a rota correta; busca e filtros alteram os resultados; preferência sobrevive à navegação |
| 2 | Ritmo | Ditado com pulsação, BPM ajustável, contagem inicial, subdivisão, gravação de toques, tolerância temporal e dica | Ritmo escutado pode ser repetido por toque; feedback mostra erro temporal; tentativa fica no histórico |
| 3 | Escalas e acordes | Exercícios auditivos de identificar tipo de escala e qualidade do acorde, progressivos e com nota-raiz/referência | Áudio reproduzível, resposta validada, explicação de graus/semitons e progresso salvo |
| 4 | Braço de violão | Simulador de seis cordas e trastes com áudio, nomes de notas, oitavas e toque livre | Mapa E-A-D-G-B-E coerente; cada célula toca nota correta e funciona por toque/mouse |
| 5 | Perfil e preferências | Cifras/solfejo, visibilidade de rótulos, BPM inicial, imagem de perfil | Preferências carregam em outros módulos; imagem só é confirmada após upload e gravação no perfil |
| 6 | Relatório acionável | Consolidar categorias, erros repetidos e sugestões de revisão; exportação local opcional | Relatório cita conteúdo registrado e recomenda exercícios existentes |
| 7 | Lembretes e conquistas | Agendamento local opt-in e notificação local ao alcançar conquista, com configurações | Permissão solicitada só ao ativar; agenda pode ser alterada/cancelada; erros não bloqueiam estudo |
| 8 | Administração | Definir superfície e controles administrativos | Não expor consulta/edição de todos os perfis por cliente. Exigir custom claims e regras/Cloud Functions testadas; sem infraestrutura segura, deixar documentado como bloqueio operacional |
| 9 | Qualidade / aceitação | Testes de lógica, widgets e fluxos; análise estática; build mobile | Suítes passam; `flutter analyze` limpo; compilar Android e registrar o que ainda requer aparelho físico |

## Ordem de implementação desta rodada

1. Entregar as etapas 1–7 nos limites técnicos do app Flutter/Firebase existente.
2. Revisar o funcionamento das trilhas, histórico, gamificação e teclado sem remover os fluxos existentes.
3. Não habilitar ferramentas administrativas através de regras abertas: o PDF lista um ator administrador, mas não define autorização nem backend para esse ator. Registrar os requisitos de segurança para a próxima implantação.
4. Atualizar a auditoria de cobertura e executar `flutter test`, `flutter analyze` e builds depois das mudanças.

## Riscos técnicos e dependências

- Upload de foto requer Firebase Storage habilitado e regras que limitem acesso ao dono do arquivo; se o bucket ou as regras não existirem, o perfil precisa mostrar erro e manter a foto anterior.
- Lembrete local requer permissão/notificações do sistema e setup Android/iOS; entrega push remoto exige backend separado.
- Latência de áudio, rotação e multitouch precisam de validação em aparelhos reais; build desktop não comprova esse comportamento.
- As amostras de violão vêm da camada fingerstyle de Meta Nylon Guitar; o mapeamento conserva corda, nota e traste, em vez de alterar notas de piano por pitch shifting.
- Ditado rítmico baseado em toque valida a precisão do toque e não substitui detecção de áudio por microfone.

## Execução e aceite desta rodada

As etapas 1 a 7 têm rotas funcionais no app. O exercício de ritmo mede batidas em relação ao BPM; escalas e acordes compartilham a progressão por habilidade; o catálogo abre cada fluxo; as preferências são locais; e o relatório transforma resultados registrados em sugestões de revisão. A imagem depende de Firebase Storage e as notificações dependem de permissão do sistema. A auditoria em `auditoria-escopo-tcc.md` registra o aceite e os itens que ainda dependem de ambiente ou teste em aparelho.

O painel administrativo permanece como dependência de segurança: custom claims e regras de servidor não podem ser substituídos por uma condição na interface. Nenhuma regra remota foi publicada nesta alteração.
