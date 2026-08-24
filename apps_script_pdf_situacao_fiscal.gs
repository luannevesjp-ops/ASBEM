// ============================================================================
// APPS SCRIPT — PDF SITUAÇÃO FISCAL (isolado, só LEITURA no Google Drive)
// ============================================================================
// Não grava em nada (nem na planilha GERAL, nem em nenhuma outra aba) - só
// lista uma pasta do Drive e devolve, pra cada empresa (Código), o link do
// PDF mais recente de SITUAÇÃO FISCAL. Isolado dos outros Apps Script deste
// projeto (apps_script_empresas.gs, apps_script_cliente_fornecedor.gs) - de
// propósito, mesmo raciocínio: um bug aqui não pode derrubar os outros.
//
// Este arquivo é só cópia/backup - colar aqui NÃO atualiza o que está
// publicado. Passos pra publicar de verdade:
//   1. script.google.com > Novo projeto > colar este código.
//   2. Trocar FOLDER_ID abaixo pelo ID da pasta do Drive onde os PDFs de
//      SITUAÇÃO FISCAL ficam salvos (é o trecho depois de /folders/ na URL
//      da pasta quando você abre ela no navegador).
//   3. No editor, rodar a função "autorizar" uma vez (▶ Executar) e aceitar
//      a tela de permissão do Google (acesso ao Drive).
//   4. Implantar > Nova implantação > tipo "Aplicativo da Web".
//      Executar como: Eu. Quem pode acessar: Qualquer pessoa.
//      IMPORTANTE: sempre criar implantação NOVA (não editar uma existente) -
//      editar uma implantação já publicada às vezes não aplica a mudança de
//      permissão direito (mesmo problema já visto nos outros Apps Script
//      deste projeto).
//   5. Colar a URL gerada em APPS_SCRIPT_PDF_SITUACAO_FISCAL_URL, no topo da
//      função pagina_situacao_fiscal_empresas() em ASBEM_Gestor_Fiscal.py.
//
// Se um dia mudar de pasta ou de nome de arquivo: editar aqui pra manter o
// histórico, colar no editor publicado, salvar, e em "Implantar > Gerenciar
// implantações > editar (lápis) > Nova versão > Implantar" pra manter a
// MESMA URL (senão quebra a constante no Python).
// ============================================================================

var FOLDER_ID = "1jkpwj3X4X6e0vh9fI70U8GlJNk-b7gn3";

// Nome esperado do arquivo: "_<código>_SITUAÇÃO FISCAL MM-AAAA.pdf"
// Ex.: "_3_SITUAÇÃO FISCAL 08-2026.pdf"  ->  código = "3", mês/ano = 08/2026
var REGEX_CODIGO = /^_(\d+)_/;
var REGEX_MES_ANO = /(\d{2})-(\d{4})/;

function doGet(e) {
  var pasta = DriveApp.getFolderById(FOLDER_ID);
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
// pelo Python cai em erro de autorização.
function autorizar() {
  Logger.log(DriveApp.getFolderById(FOLDER_ID).getName());
}
