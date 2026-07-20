# Sistema Mestre — Arquitetura Técnica

> Rascunho. Depois que a conexão com o Supabase estiver testada e funcionando,
> revisar este arquivo e substituir a cópia no projeto (junto com
> instrucoes-projeto.md, se algo do §6 mudar de "pendência" pra "decidido").

## Decisão de stack (2026-07-20)

- **Banco de dados / backend:** Supabase (Postgres gerenciado + Auth + Storage).
- **Hospedagem do front-end:** ainda não decidida — o app continua um front-end
  estático (HTML puro, sem build step), então serve qualquer hospedagem
  estática (Vercel, Netlify, GitHub Pages, ou o Storage do próprio Supabase).
- **Autenticação:** Supabase Auth (email/senha), um usuário por pessoa da
  equipe (vendedor/produção). Ainda não implementada no front-end.
- **Estrutura de dados:** ver `supabase/schema.sql` — tabelas `orcamentos`,
  `pecas`, `ordens_producao`, `estoque_mp`, `movimentos_estoque`.
- **Numeração de orçamento:** sequência do Postgres (`orcamento_numero_seq`),
  começando em 3000, garante unicidade mesmo com múltiplos vendedores
  simultâneos (o array em memória do protótipo não garantia isso).
- **Preços e fórmulas de cálculo:** continuam vivendo no front-end
  (`index.html`), como constantes JS — não foram movidos pro banco. Só dados
  transacionais (orçamentos, peças, produção, estoque) são persistidos.
  Motivo: mudar isso seria uma decisão de arquitetura adicional, fora do
  escopo desta sessão — regra de trabalho #1 exige confirmação explícita
  antes de qualquer mudança em preço/fórmula/regra de cálculo.
- **Estoque:** sobe por entrada manual, desce por baixa manual na tela de
  Produção — mesma regra do protótipo, agora persistida via
  `movimentos_estoque` + funções `incrementar_estoque`/`decrementar_estoque`
  (atômicas, evitam corrida entre baixas simultâneas).
- **RLS:** habilitado em todas as tabelas. Política única por enquanto:
  qualquer usuário autenticado tem acesso total (sem separação de permissão
  vendedor x produção ainda — ver pendências).

## Pendências que continuam abertas (ver instrucoes-projeto.md §6)

- Capacidade diária real de produção.
- Preço/m² de persiana Vertical, Horizontal e Romana.
- Se a baixa de estoque continua manual ou passa a ser sugerida
  automaticamente ao mudar status da OP (hoje: continua manual, só que
  agora persistida).
- CPF em texto simples — LGPD ainda pendente de tratamento (hoje: campo
  `cliente_cpf` em texto puro na tabela `orcamentos`, sem criptografia).
- Geração de PDF do orçamento/OP e histórico consultável.

## Pendências novas, adicionadas com a integração ao Supabase

- ~~Tela de login (Supabase Auth)~~ — feito: `public/index.html` já pede
  login antes de mostrar qualquer tela, usando `auth.signInWithPassword`.
- ~~Upload de foto da peça pro Supabase Storage~~ — feito: bucket
  `fotos-pecas` (`supabase/storage.sql`), upload em `enviarFotoPeca()` no
  `js/db.js`, chamado antes de gravar o orçamento.
- Separação de permissão por papel (vendedor só vê/edita orçamento, produção
  só vê/edita OP) — ainda não feito, RLS trata todo autenticado igual.
- Hospedagem definitiva do front-end — ainda não decidida.
- Conexão testada só por leitura de código (checagem de sintaxe) — falta
  teste real num navegador contra o projeto Supabase `cortinas-app`.
