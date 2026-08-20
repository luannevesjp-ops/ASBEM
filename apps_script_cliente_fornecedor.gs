// ============================================================================
// Apps Script — CLIENTES/FORNEC CNPJ (isolado, projeto/URL própria)
// ============================================================================
// Guardado aqui só como referência/backup — editar este arquivo local NÃO
// atualiza o script publicado. Pra mudar o comportamento de gravação:
//   1) edite este arquivo (mantém o histórico no repositório),
//   2) copie o conteúdo pra dentro do editor em script.google.com,
//   3) Implantar > Gerenciar implantações > editar (lápis) > Nova versão >
//      Implantar (assim a URL publicada continua a mesma, sem precisar
//      trocar a constante APPS_SCRIPT_CLI_FORNEC_URL no Python).
//
// Diferente do Apps Script de EMPRESAS (que grava célula a célula na aba
// GERAL, sem nunca limpar a aba inteira): aqui é seguro fazer
// clearContents() + reescrever tudo, porque as abas DADOS e DADOS_META só
// existem pra este recurso e são geradas 100% a partir do Python — nenhum
// outro sistema lê ou escreve nelas.
//
// A aba DADOS já foi criada manualmente pelo usuário; DADOS_META é criada
// automaticamente pelo próprio script na primeira execução, se não existir.
// ============================================================================

// Mesmo SHEET_ID usado em todo o Python (GOOGLE_SHEET_URL/SHEET_ID em
// ASBEM_Gestor_Fiscal.py). Usa openById() em vez de getActiveSpreadsheet()
// de propósito: getActiveSpreadsheet() só funciona se este projeto foi
// criado de DENTRO da planilha (Extensões > Apps Script) — se foi criado
// como projeto avulso em script.google.com, ela não sabe qual planilha usar
// e quebra com "Ocorreu um erro desconhecido". openById() funciona nos dois
// casos, só precisa que a conta que autorizar o script tenha acesso a ela.
var SHEET_ID = "1uuNhoIYTbAECnlEw64eFSKD558WCcCXpIqcJAQsgSSM";
var NOME_ABA_DADOS = "DADOS";
var NOME_ABA_META  = "DADOS_META";
var CABECALHO_DADOS = ["Código", "Empresa", "Tipo", "Nome", "CNPJ", "Espécie NF", "Valor", "Base ICMS", "Valor ICMS"];

// Rode esta função UMA VEZ manualmente no editor (selecionar "autorizar" no
// dropdown de funções ao lado do botão ▶ Executar, e clicar em Executar) —
// só assim o Google mostra a tela de autorização (Revisar permissões >
// Avançado > Ir para o projeto > Permitir). Sem isso, a implantação como Web
// App fica bloqueada (401) mesmo com "Quem pode acessar: Qualquer pessoa".
function autorizar() {
  Logger.log(SpreadsheetApp.openById(SHEET_ID).getName());
}

function doPost(e) {
  var body = JSON.parse(e.postData.contents);
  var ss = SpreadsheetApp.openById(SHEET_ID);

  if (body.cli_fornec) {
    return gravarCliFornec(ss, body.cli_fornec);
  }

  return ContentService.createTextOutput(JSON.stringify({status: "erro", message: "payload não reconhecido"}))
    .setMimeType(ContentService.MimeType.JSON);
}

function gravarCliFornec(ss, dados) {
  try {
    var abaDados = ss.getSheetByName(NOME_ABA_DADOS);
    if (!abaDados) {
      abaDados = ss.insertSheet(NOME_ABA_DADOS);
    }
    abaDados.clearContents();
    abaDados.getRange(1, 1, 1, CABECALHO_DADOS.length).setValues([CABECALHO_DADOS]);

    var linhas = dados.linhas || [];
    if (linhas.length > 0) {
      var COLS_TEXTO = ["Código", "CNPJ"];
      var valores = linhas.map(function (l) {
        return CABECALHO_DADOS.map(function (col) {
          var v = l[col] !== undefined && l[col] !== null ? l[col] : "";
          // prefixa com apóstrofo nas colunas que precisam ficar como texto
          // (força o Sheets a não reinterpretar "01847854000332" como
          // número e comer o zero à esquerda — o apóstrofo em si não fica
          // gravado como caractere, é só o indicador clássico de texto)
          if (COLS_TEXTO.indexOf(col) !== -1 && v !== "") {
            v = "'" + v;
          }
          return v;
        });
      });
      // além do apóstrofo, formata a coluna como texto ANTES do setValues e
      // força o commit com flush() — sem isso, setNumberFormat("@") sozinho
      // às vezes não é respeitado a tempo pelo setValues() logo em seguida
      // (comportamento confirmado na prática: o CNPJ voltou como número
      // mesmo com o setNumberFormat aplicado antes, sem o flush no meio).
      COLS_TEXTO.forEach(function (nomeCol) {
        var idx = CABECALHO_DADOS.indexOf(nomeCol) + 1;
        if (idx > 0) {
          abaDados.getRange(2, idx, valores.length, 1).setNumberFormat("@");
        }
      });
      SpreadsheetApp.flush();
      abaDados.getRange(2, 1, valores.length, CABECALHO_DADOS.length).setValues(valores);
    }

    var abaMeta = ss.getSheetByName(NOME_ABA_META);
    if (!abaMeta) {
      abaMeta = ss.insertSheet(NOME_ABA_META);
    }
    abaMeta.clearContents();
    abaMeta.getRange(1, 1, 4, 2).setValues([
      ["Campo", "Valor"],
      ["Arquivo Fornecedores", dados.arquivo_fornecedor || ""],
      ["Arquivo Clientes", dados.arquivo_cliente || ""],
      ["Atualizado em", dados.atualizado_em || ""],
    ]);

    return ContentService.createTextOutput(JSON.stringify({status: "ok"}))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (erro) {
    return ContentService.createTextOutput(JSON.stringify({status: "erro", message: String(erro)}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
