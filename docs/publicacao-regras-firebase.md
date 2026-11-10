# Regras de segurança do Firebase — preparação para publicação

**Data:** 10/11/2026
**Projeto:** `melodyhub-4fad1`
**Situação:** **NÃO PUBLICADO.** A publicação aguarda a confirmação do autor.

## Regras atualmente publicadas (backup)

Cópia salva em `docs/firebase-regras-anteriores/firestore.rules`.

```
match /{document=**} {
  allow read, write: if true;
}
```

**Risco:** o banco está aberto para leitura, escrita e exclusão por qualquer pessoa, sem
autenticação, incluindo nome e e-mail dos usuários. O próprio console do Firebase mostra
o alerta "Suas regras de segurança estão definidas como públicas".

## Inventário

- **Firestore:** só existe a coleção de raiz `usuarios`, com a subcoleção `historico`.
- **App:** o código em `lib/` só acessa `usuarios/{uid}` e `usuarios/{uid}/historico`
  do próprio usuário autenticado. Não há consultas a outros perfis nem `collectionGroup`.
- **Storage:** **não ativado.** No plano Spark, ativá-lo exige migrar para o plano Blaze,
  com conta de faturamento. Por isso, `storage.rules` não pode ser publicado, e o envio de
  foto de perfil do app falha hoje (ver Tarefa 8 em `docs/tarefas-codex.md`).

## Testes no Laboratório de testes de regras do console

As regras testadas são as de `firestore.rules` do repositório, coladas no editor do
console sem publicar.

| # | Operação | Caminho | Autenticação | Dados | Esperado | Obtido |
|---|---|---|---|---|---|---|
| 1 | get | `usuarios/teste1` | uid `teste1` | — | Permitir | Permitido |
| 2 | get | `usuarios/teste2` | uid `teste1` | — | Negar | Negado |
| 3 | get | `usuarios/teste1` | não autenticado | — | Negar | Negado |
| 4 | get | `outra_colecao/x` | uid `teste1` | — | Negar | Negado |
| 5 | get | `usuarios/teste1/historico/evento1` | uid `teste1` | — | Permitir | Permitido |
| 6 | get | `usuarios/teste1/historico/evento1` | uid `teste2` | — | Negar | Negado |
| 7 | create | `usuarios/teste1` | uid `teste1` | `xp: 10` | Permitir | Permitido |
| 8 | create | `usuarios/teste1` | uid `teste1` | `xp: -5` | Negar | Negado |
| 9 | create | `usuarios/teste2` | uid `teste1` | `xp: 10` | Negar | Negado |
| 10 | create | `usuarios/teste1/historico/e1` | uid `teste1` | — | Permitir | Permitido |

Todos os resultados conferem com o esperado.

## Para publicar (quando autorizado)

1. Console → Firestore → Regras: colar o conteúdo de `firestore.rules` e clicar em **Publicar**.
   Pelo CLI: `firebase deploy --only firestore:rules --project melodyhub-4fad1`. Não use
   `firebase deploy` sem `--only` enquanto o Storage não estiver ativo.
2. Logo depois, no app: fazer login, abrir o perfil, responder um exercício, conferir o
   histórico e trocar cifra/solfejo.
3. **Rollback:** se houver erro de permissão, publicar o conteúdo de
   `docs/firebase-regras-anteriores/firestore.rules` e registrar o erro aqui.

## Registro de publicação

- Publicado em: _(pendente)_
- Testes pós-publicação: _(pendente)_
- Rollback: _(não aplicável)_
