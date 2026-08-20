// ============================================================================
// Apps Script EXCLUSIVO para gravar edições/inclusões de empresas na aba
// GERAL, feito pela tela EMPRESAS do ASBEM_Exectar_Sistemas.py.
//
// É um projeto e uma URL totalmente separados do Apps Script que já alimenta
// CERTIFICADOS/EMAIL/MENSAGEM (usado pelo ASBEM_Gestor_Fiscal.py) — um bug
// aqui não tem como afetar aquela integração, porque não roda no mesmo
// processo nem na mesma implantação.
//
// Como implantar:
// 1. https://script.google.com > Novo projeto.
// 2. Apagar o conteúdo padrão (Code.gs) e colar este arquivo inteiro.
// 3. No menu Executar, escolher a função "autorizar" e rodar uma vez — vai
//    pedir permissão pra abrir a planilha pelo ID, aceitar.
// 4. Implantar > Nova implantação > tipo "App da Web":
//      - Executar como: Eu (sua conta)
//      - Quem pode acessar: Qualquer pessoa
// 5. Copiar a URL /exec gerada e colar em APPS_SCRIPT_EMPRESAS_URL no
//    ASBEM_Exectar_Sistemas.py.
// ============================================================================

var SHEET_ID  = '1uuNhoIYTbAECnlEw64eFSKD558WCcCXpIqcJAQsgSSM';
var ABA_GERAL = 'GERAL';

function autorizar() {
  // Só existe pra forçar a tela de autorização na primeira execução manual.
  SpreadsheetApp.openById(SHEET_ID);
}

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    if (!data.empresas) {
      return _resposta({status: 'error', message: 'payload sem "empresas"'});
    }

    var ss = SpreadsheetApp.openById(SHEET_ID);
    _atualizarEmpresasGeral(ss, data.empresas);

    return _resposta({status: 'ok'});
  } catch (err) {
    return _resposta({status: 'error', message: err.toString()});
  }
}

function _resposta(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

// Nunca clearContents / nunca mexe em coluna ou linha existente. Só faz
// setValue célula a célula: atualiza campos de empresa já cadastrada
// (localizada pelo CNPJ) ou preenche a próxima linha livre para empresa nova.
function _atualizarEmpresasGeral(ss, empresas) {
  var ws = ss.getSheetByName(ABA_GERAL);
  if (!ws) throw new Error('Aba GERAL não encontrada');

  var ultimaColuna = ws.getLastColumn();
  var cabecalho = ws.getRange(1, 1, 1, ultimaColuna).getValues()[0];
  var colIndex = {};
  for (var i = 0; i < cabecalho.length; i++) {
    var nome = String(cabecalho[i]).trim();
    if (nome) colIndex[nome] = i + 1; // 1-based, para getRange
  }

  var edicoes = empresas.edicoes || [];
  for (var e = 0; e < edicoes.length; e++) {
    var linha = _localizarLinhaPorCnpj(ws, colIndex, edicoes[e].cnpj);
    if (!linha) continue;
    var campos = edicoes[e].campos || {};
    for (var nomeCampo in campos) {
      var col = colIndex[nomeCampo];
      if (col) ws.getRange(linha, col).setValue(campos[nomeCampo]);
    }
  }

  // linhaLivre é calculada UMA vez e incrementada localmente a cada empresa nova
  // (em vez de chamar ws.getLastRow() de novo a cada iteração) porque o Apps
  // Script não garante que uma leitura enxergue um setValue anterior na MESMA
  // execução — com getLastRow() dentro do loop, um lote com várias empresas
  // novas de uma vez podia cair todo na mesma linha e se sobrescrever.
  var novas = empresas.novas || [];
  var linhaLivre = ws.getLastRow() + 1;
  for (var n = 0; n < novas.length; n++) {
    var camposNovos = novas[n].campos || {};
    for (var nomeCampoNovo in camposNovos) {
      var colNovo = colIndex[nomeCampoNovo];
      if (colNovo) ws.getRange(linhaLivre, colNovo).setValue(camposNovos[nomeCampoNovo]);
    }
    linhaLivre++;
  }
}

function _localizarLinhaPorCnpj(ws, colIndex, cnpjAlvo) {
  var colCnpj = colIndex['CNPJ'];
  if (!colCnpj) return null;

  var alvo = _normalizaCnpj(cnpjAlvo);
  var ultimaLinha = ws.getLastRow();
  if (ultimaLinha < 2) return null;

  var valores = ws.getRange(2, colCnpj, ultimaLinha - 1, 1).getValues();
  for (var i = 0; i < valores.length; i++) {
    if (_normalizaCnpj(valores[i][0]) === alvo) {
      return i + 2; // +1 pq a leitura começou na linha 2, +1 pq índice é 0-based
    }
  }
  return null;
}

function _normalizaCnpj(valor) {
  var bruto = String(valor);
  var pontoIdx = bruto.indexOf('.');
  // planilha guarda CNPJ como número (perde zero à esquerda); se vier como
  // float serializado, corta na parte inteira antes de completar com zeros.
  var digitos = (pontoIdx !== -1 ? bruto.substring(0, pontoIdx) : bruto).replace(/\D/g, '');
  while (digitos.length < 14) digitos = '0' + digitos;
  return digitos.substring(0, 14);
}
