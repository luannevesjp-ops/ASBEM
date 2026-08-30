// ============================================================================
// APPS SCRIPT — PDF SITUAÇÃO FISCAL (isolado, só LEITURA no Google Drive)
// ============================================================================
// COMPARTILHADO por todos os escritórios (ASBEM, VIDAL, VS, WR, MODELO...) -
// implantado UMA VEZ SÓ, e cada escritório passa qual pasta ler pelo parâmetro
// ?escritorio=<chave> na URL. Faz sentido compartilhar aqui (ao contrário dos
// outros Apps Script deste projeto, que são isolados por FEATURE) porque é a
// MESMA feature (lupa de PDF de Situação Fiscal) rodando pra clientes
// diferentes, todos sob a mesma conta Google - um só script pra manter, uma
// só URL, em vez de reimplantar o mesmo código 4-5 vezes.
//
// Não grava em nada (nem em planilha nenhuma) - só lista a pasta do Drive do
// escritório pedido e devolve, pra cada empresa (Código), o link do PDF mais
// recente de SITUAÇÃO FISCAL.
//
// Este arquivo é só cópia/backup - colar aqui NÃO atualiza o que está
// publicado. Passos pra publicar/atualizar de verdade:
//   1. script.google.com/home > abrir o projeto já existente (o mesmo que já
//      serve a ASBEM) - NÃO criar um novo, senão a URL muda e quebra o que já
//      está configurado no Python da ASBEM.
//   2. Colar este código no lugar do antigo.
//   3. Preencher PASTAS_POR_ESCRITORIO abaixo com o ID da pasta do Drive de
//      cada escritório (pedaço da URL depois de /folders/ quando você abre a
//      pasta no navegador).
//   4. Implantar > Gerenciar implantações > editar (lápis) > Nova versão >
//      Implantar. IMPORTANTE: usar "Nova versão" numa implantação EXISTENTE
//      (não criar implantação nova) pra manter a MESMA URL - senão quebra a
//      constante já configurada em ASBEM_Gestor_Fiscal.py.
//   5. Em cada *_Gestor_Fiscal.py, colar a MESMA URL em
//      APPS_SCRIPT_PDF_SITUACAO_FISCAL_URL, só que com o parâmetro do
//      escritório no final, ex.:
//      APPS_SCRIPT_PDF_SITUACAO_FISCAL_URL = "<url>?escritorio=vs"
//
// Se um dia mudar de pasta ou de nome de arquivo de algum escritório: editar
// aqui pra manter o histórico, colar no editor publicado, salvar, e de novo
// "Nova versão" (nunca implantação nova).
// ============================================================================

// Preencher com o ID de cada pasta do Drive (pedaço depois de /folders/ na
// URL da pasta). A chave é o que cada escritório manda em ?escritorio=<chave>.
var PASTAS_POR_ESCRITORIO = {
  "asbem": "1jkpwj3X4X6e0vh9fI70U8GlJNk-b7gn3",
  "vidal": "1mkxExSWIuxQmsKJPo9qd6Jd-Zw4bNqv5",
  "vs": "1oz4pwxZEATppAPs5f2zTYAQXlSVmiPUJ",
  "wr": "1LT54Rn03mYapOmjSb4ZNoNBzWHHg5Pqt",
  "visao": "15id3T3rQKiWJfYVrQs5a96EQY5ZOwQcw",
  "vj": "1z1c4v8FGXHuEAYeRhl8T-7sRCJmvSMFn",
};

// Nome esperado do arquivo: "_<código>_SITUAÇÃO FISCAL MM-AAAA.pdf"
// Ex.: "_3_SITUAÇÃO FISCAL 08-2026.pdf"  ->  código = "3", mês/ano = 08/2026
var REGEX_CODIGO = /^_(\d+)_/;
var REGEX_MES_ANO = /(\d{2})-(\d{4})/;

function doGet(e) {
  var escritorio = (e.parameter.escritorio || "").toLowerCase().trim();
  var folderId = PASTAS_POR_ESCRITORIO[escritorio];

  if (!escritorio || !folderId) {
    return ContentService.createTextOutput(JSON.stringify({
      erro: "Parâmetro ?escritorio=<chave> ausente ou não configurado em PASTAS_POR_ESCRITORIO.",
      escritorio_recebido: escritorio,
    })).setMimeType(ContentService.MimeType.JSON);
  }

  var pasta = DriveApp.getFolderById(folderId);
  var arquivos = pasta.getFilesByType(MimeType.PDF);

  // código -> {url, ordenacao} do PDF mais recente já visto pra esse código
  var maisRecentePorCodigo = {};

  while (arquivos.hasNext()) {
    var arquivo = arquivos.next();
    var nome = arquivo.getName();

    var mCodigo = nome.match(REGEX_CODIGO);
    if (!mCodigo) continue; // arquivo fora do padrão esperado - ignora
    var codigo = mCodigo[1];

    var restante = nome.substring(mCodigo[0].length);
    var mData = restante.match(REGEX_MES_ANO);
    var ordenacao = 0;
    if (mData) {
      var mes = parseInt(mData[1], 10);
      var ano = parseInt(mData[2], 10);
      ordenacao = ano * 100 + mes; // ex: 08/2026 -> 202608, dá pra comparar direto
    }

    var atual = maisRecentePorCodigo[codigo];
    if (!atual || ordenacao >= atual.ordenacao) {
      maisRecentePorCodigo[codigo] = { url: arquivo.getUrl(), ordenacao: ordenacao };
    }
  }

  // devolve só {codigo: url} pro Python - mais simples de consumir
  var resultado = {};
  for (var codigo in maisRecentePorCodigo) {
    resultado[codigo] = maisRecentePorCodigo[codigo].url;
  }

  return ContentService.createTextOutput(JSON.stringify(resultado))
      .setMimeType(ContentService.MimeType.JSON);
}

// Rodar manualmente uma vez no editor (▶ Executar) antes de implantar, pra
// conceder a permissão de acesso ao Drive - senão a primeira chamada feita
// pelo Python cai em erro de autorização. Roda em TODAS as pastas configuradas
// de uma vez (a autorização do Drive vale pro escopo inteiro, não por pasta).
function autorizar() {
  for (var chave in PASTAS_POR_ESCRITORIO) {
    var id = PASTAS_POR_ESCRITORIO[chave];
    if (!id) continue;
    Logger.log(chave + " -> " + DriveApp.getFolderById(id).getName());
  }
}
