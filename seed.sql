// ============================================================================
// db.js — camada de acesso ao Supabase
// Único arquivo que sabe que existe um banco por trás. O resto do app
// (index.html) continua falando a mesma "língua" de sempre (orcamentos,
// itensOrcamento, producao, estoqueMP) — as funções de mapear* abaixo fazem
// a ponte entre o formato do banco e o formato que o app já usa.
// ============================================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ---------------------------------------------------------------------------
// AUTENTICAÇÃO
// ---------------------------------------------------------------------------
export async function getSessao() {
  const { data } = await supabase.auth.getSession();
  return data.session;
}
export async function entrar(email, senha) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password: senha });
  if (error) throw error;
  return data.session;
}
export async function sair() {
  await supabase.auth.signOut();
}

// ---------------------------------------------------------------------------
// MAPEAMENTO banco <-> formato interno do app
// ---------------------------------------------------------------------------

// peça como o app já monta em itensOrcamento (ver adicionarPeca() no index.html)
function pecaParaBanco(p) {
  return {
    local: p.local,
    tipo_peca: p.tipoPeca,
    largura: p.largura,
    altura: p.altura,
    configuracao: {
      camadas: Array.from(p.camadas || []),
      instalacao: p.instalacao,
      varianteTrilho: p.varianteTrilho,
      varianteVarao: p.varianteVarao,
      cromado: p.cromado,
      persianaTipo: p.persianaTipo,
    },
    detalhe_calculo: p.custoItens,
    materiais: p.materiaisMP,
    valor: p.total,
    foto_url: p.fotoUrl || null, // preenchido depois do upload, ver enviarFotoPeca()
  };
}

function pecaDoBanco(row) {
  return {
    tipoPeca: row.tipo_peca,
    local: row.local,
    largura: Number(row.largura),
    altura: Number(row.altura),
    camadas: row.configuracao?.camadas || [],
    instalacao: row.configuracao?.instalacao || null,
    varianteTrilho: row.configuracao?.varianteTrilho || 'simples',
    varianteVarao: row.configuracao?.varianteVarao || 'grosso',
    cromado: !!row.configuracao?.cromado,
    persianaTipo: row.configuracao?.persianaTipo || 'rolo_screen',
    foto: row.foto_url || null,
    custoItens: row.detalhe_calculo,
    materiaisMP: row.materiais,
    total: Number(row.valor),
  };
}

function orcamentoDoBanco(row) {
  const dataCriacao = new Date(row.data_criacao);
  return {
    id: row.id,
    numero: row.numero,
    cliente: row.cliente_nome,
    telefone: row.cliente_telefone,
    cpf: row.cliente_cpf || '—',
    cidade: row.cliente_cidade || '—',
    itens: (row.pecas || []).map(pecaDoBanco),
    total: Number(row.total),
    dataCriacao,
    validadeDias: row.validade_dias,
    status: row.status,
    dataAprovacao: row.data_aprovacao ? new Date(row.data_aprovacao) : null,
  };
}

function opDoBanco(row) {
  const pecas = (row.orcamentos?.pecas || []).map(pecaDoBanco);
  return {
    id: row.id,
    op: `OP-${row.numero}`,
    orcamentoId: row.orcamento_id,
    orcamentoNumero: row.numero,
    cliente: row.orcamentos?.cliente_nome,
    telefone: row.orcamentos?.cliente_telefone,
    cpf: row.orcamentos?.cliente_cpf || '—',
    cidade: row.orcamentos?.cliente_cidade || '—',
    dataAprovacao: new Date(row.data_aprovacao),
    pecas,
    dataEntregaPrevista: new Date(row.data_entrega_prevista + 'T00:00:00'),
    status: row.status,
    baixaFeita: row.baixa_materiais_feita,
  };
}

// ---------------------------------------------------------------------------
// ORÇAMENTOS
// ---------------------------------------------------------------------------

export async function listarOrcamentos() {
  const { data, error } = await supabase
    .from('orcamentos')
    .select('*, pecas(*)')
    .order('numero', { ascending: false });
  if (error) throw error;
  return data.map(orcamentoDoBanco);
}

// clienteForm = {nome, telefone, cpf, cidade, validadeDias}; itens = itensOrcamento (peças já calculadas)
export async function salvarOrcamento(clienteForm, itens) {
  const total = itens.reduce((s, p) => s + p.total, 0);

  const { data: orcamento, error: erroOrc } = await supabase
    .from('orcamentos')
    .insert({
      cliente_nome: clienteForm.nome.trim(),
      cliente_telefone: clienteForm.telefone.trim(),
      cliente_cpf: clienteForm.cpf.trim() || null,
      cliente_cidade: clienteForm.cidade.trim() || null,
      validade_dias: clienteForm.validadeDias,
      total,
    })
    .select()
    .single();
  if (erroOrc) throw erroOrc;

  const linhas = itens.map(p => ({ orcamento_id: orcamento.id, ...pecaParaBanco(p) }));
  const { error: erroPecas } = await supabase.from('pecas').insert(linhas);
  if (erroPecas) throw erroPecas;

  return orcamento.numero;
}

// Aprova (registra sinal) e gera a OP — prazo fixo de 30 dias corridos da aprovação
export async function aprovarOrcamentoNoBanco(orcamentoId) {
  const agora = new Date();
  const entrega = new Date(agora);
  entrega.setDate(entrega.getDate() + 30);

  const { data: orcamento, error: erroAprov } = await supabase
    .from('orcamentos')
    .update({ status: 'aprovado', data_aprovacao: agora.toISOString() })
    .eq('id', orcamentoId)
    .select()
    .single();
  if (erroAprov) throw erroAprov;

  const { error: erroOP } = await supabase.from('ordens_producao').insert({
    orcamento_id: orcamento.id,
    numero: orcamento.numero,
    data_aprovacao: agora.toISOString(),
    data_entrega_prevista: entrega.toISOString().slice(0, 10),
  });
  if (erroOP) throw erroOP;
}

// Busca o id interno do orçamento a partir do número (a UI trabalha com número)
export async function idOrcamentoPorNumero(numero) {
  const { data, error } = await supabase.from('orcamentos').select('id').eq('numero', numero).single();
  if (error) throw error;
  return data.id;
}

// ---------------------------------------------------------------------------
// PRODUÇÃO
// ---------------------------------------------------------------------------

export async function listarProducao() {
  const { data, error } = await supabase
    .from('ordens_producao')
    .select('*, orcamentos(cliente_nome, cliente_telefone, cliente_cpf, cliente_cidade, pecas(*))')
    .order('numero', { ascending: true });
  if (error) throw error;
  return data.map(opDoBanco);
}

export async function avancarStatusNoBanco(opId, novoStatus) {
  const { error } = await supabase.from('ordens_producao').update({ status: novoStatus }).eq('id', opId);
  if (error) throw error;
}

// materiaisAgregados: [{id, quantidade}] (saída de agregarMateriais() no index.html)
export async function darBaixaNoBanco(opId, numeroOP, materiaisAgregados) {
  const movimentos = materiaisAgregados.map(m => ({
    item_id: m.id,
    tipo: 'saida',
    quantidade: m.quantidade,
    origem: `OP-${numeroOP}`,
  }));
  const { error: erroMov } = await supabase.from('movimentos_estoque').insert(movimentos);
  if (erroMov) throw erroMov;

  for (const m of materiaisAgregados) {
    const { error } = await supabase.rpc('decrementar_estoque', { p_item_id: m.id, p_quantidade: m.quantidade });
    if (error) throw error;
  }

  const { error: erroOP } = await supabase
    .from('ordens_producao')
    .update({ baixa_materiais_feita: true, baixa_materiais_em: new Date().toISOString() })
    .eq('id', opId);
  if (erroOP) throw erroOP;
}

// ---------------------------------------------------------------------------
// ESTOQUE DE MATÉRIA-PRIMA
// ---------------------------------------------------------------------------

export async function listarEstoque() {
  const { data, error } = await supabase.from('estoque_mp').select('*').order('categoria');
  if (error) throw error;
  return data.map(i => ({ id: i.id, nome: i.nome, unidade: i.unidade, categoria: i.categoria, saldo: Number(i.saldo), minimo: Number(i.minimo) }));
}

export async function registrarEntradaNoBanco(itemId, quantidade) {
  const { error: erroMov } = await supabase
    .from('movimentos_estoque')
    .insert({ item_id: itemId, tipo: 'entrada', quantidade, origem: 'Entrada manual' });
  if (erroMov) throw erroMov;

  const { error } = await supabase.rpc('incrementar_estoque', { p_item_id: itemId, p_quantidade: quantidade });
  if (error) throw error;
}

// ---------------------------------------------------------------------------
// FOTO DA PEÇA (Supabase Storage — bucket "fotos-pecas")
// Recebe o dataURL base64 que a câmera já gera hoje no app e sobe pro Storage,
// devolvendo a URL pública pra gravar em pecas.foto_url.
// ---------------------------------------------------------------------------
export async function enviarFotoPeca(dataUrlBase64) {
  if (!dataUrlBase64) return null;
  const resposta = await fetch(dataUrlBase64);
  const blob = await resposta.blob();
  const extensao = (blob.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
  const nomeArquivo = `${crypto.randomUUID()}.${extensao}`;

  const { error } = await supabase.storage.from('fotos-pecas').upload(nomeArquivo, blob, { contentType: blob.type });
  if (error) throw error;

  const { data } = supabase.storage.from('fotos-pecas').getPublicUrl(nomeArquivo);
  return data.publicUrl;
}
