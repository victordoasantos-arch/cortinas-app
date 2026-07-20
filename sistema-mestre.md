# Cortinas App — estrutura do projeto

```
/
├── public/
│   ├── index.html          ← o app (hoje: cópia do protótipo atual, ainda em memória)
│   └── js/
│       ├── config.js       ← URL + chave anon do Supabase (você preenche)
│       └── db.js           ← toda a comunicação com o banco, isolada da UI
├── supabase/
│   ├── schema.sql          ← tabelas, sequência de numeração, funções, RLS
│   └── seed.sql            ← estoque inicial (valores copiados do protótipo)
└── docs/
    └── sistema-mestre.md   ← rascunho de decisões de arquitetura
```

## Por que essa estrutura (e não dividir tudo em arquivos)

O app hoje é ~1560 linhas de JS com estado global em memória (`orcamentos`,
`producao`, `estoqueMP` como arrays) e funções de render que leem/escrevem
direto nessas variáveis. Reescrever isso inteiro em módulos separados
(um arquivo por tela, por componente etc.) numa tacada só é arriscado: é fácil
quebrar alguma tela sem eu conseguir testar no navegador daqui.

**Alternativa recomendada:** manter a UI num arquivo só por enquanto (como já
é), mas isolar 100% do acesso a dados num módulo separado (`js/db.js`). Isso já
resolve o principal problema de "arquivo gigante" — a lógica de negócio/cálculo,
a renderização e o acesso a dados ficam claramente separados — sem o risco de
reescrever tudo de uma vez. Depois que a conexão estiver funcionando e testada,
dá pra ir quebrando o `index.html` em pedaços menores (uma tela por vez,
testando cada uma) se ainda fizer sentido.

## Passo a passo — criar o projeto Supabase

1. Acesse [supabase.com/dashboard](https://supabase.com/dashboard) e clique em
   **New project**.
2. Escolha uma organização, dê um nome (ex: `cortinas-app`), defina uma senha
   forte do banco (guarde essa senha) e escolha a região mais próxima
   (ex: São Paulo — `sa-east-1`).
3. Aguarde o projeto provisionar (leva 1-2 minutos).
4. Vá em **SQL Editor** (menu lateral) → **New query** → cole o conteúdo de
   `supabase/schema.sql` → **Run**.
5. Nova query → cole o conteúdo de `supabase/seed.sql` → **Run**.
6. Nova query → cole o conteúdo de `supabase/storage.sql` → **Run** (cria o
   bucket `fotos-pecas` e as políticas de acesso a ele).
7. Vá em **Project Settings → API**. Copie:
   - **Project URL** → cole em `SUPABASE_URL` no `public/js/config.js`
   - **anon public key** → cole em `SUPABASE_ANON_KEY` no `public/js/config.js`
8. Vá em **Authentication → Users** e crie um usuário (email/senha) pra você
   e cada pessoa da equipe que vai usar o app — o acesso ao banco exige login
   (regra de RLS: só usuário autenticado lê/grava).

## Status: já integrado

O `public/index.html` já foi conectado — não é mais só o protótipo em memória:
- Tela de login (Supabase Auth) antes de mostrar qualquer tela do app.
- Criar orçamento, aprovar (gera OP), avançar status da produção, dar baixa
  de materiais e registrar entrada de estoque → tudo grava no Supabase.
- Foto da peça sobe pro Supabase Storage (bucket `fotos-pecas`) antes de
  salvar o orçamento.
- `public/js/config.js` já está preenchido com as credenciais do projeto
  `cortinas-app`.

**Isso ainda não foi testado num navegador de verdade** (eu não tenho acesso
a rede/browser aqui) — depois de rodar os 3 SQLs acima, abra o
`public/index.html`, crie um usuário em Authentication → Users, faça login e
teste o fluxo completo: novo orçamento → aprovar → produção → baixa de
estoque → estoque MP → entrada manual. Qualquer erro, me manda a mensagem
exata que aparece (abra o Console do navegador com F12 se o erro não aparecer
na tela) que eu ajusto.
