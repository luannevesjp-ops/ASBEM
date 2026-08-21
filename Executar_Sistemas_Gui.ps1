# ============================================================================
# LUATECH / ASBEM - Executar Sistemas (tela grafica local)
#
# Script normal de PowerShell, em texto puro (nada codificado/escondido) -
# roda junto com Executar_Sistemas_Local.bat, que precisa estar na MESMA
# pasta que este arquivo pra funcionar.
#
# Mostra uma janela com um checkbox pra cada sistema (so um fica marcado
# por vez) e um botao "Executar", que abre o .exe escolhido direto na
# maquina de quem clicar - sem depender de servidor nenhum.
# ============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------------------------------------------------------
# 1) Achar a pasta EXECUSSOES: testa varias letras de unidade conhecidas
#    (a pasta de rede compartilhada aparece com letra diferente em cada
#    PC - maioria ve como H:, uma maquina especifica ve como D:\ONEDRIVE).
#    Usa curinga "?" pra achar pastas acentuadas sem depender da "code
#    page" do Windows de cada PC.
# ----------------------------------------------------------------------
function Buscar-Raiz {
    $candidatos = @("H:\", "D:\ONEDRIVE\", "D:\", "E:\", "F:\", "G:\", "I:\", "J:\", "K:\")
    foreach ($c in $candidatos) {
        if (-not (Test-Path $c)) { continue }
        $automacao = Get-ChildItem -LiteralPath $c -Filter "AUTOMA??O" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $automacao) { continue }
        $programas = Get-ChildItem -LiteralPath $automacao.FullName -Filter "PROGRAMAS" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $programas) { continue }
        $execussoes = Get-ChildItem -LiteralPath $programas.FullName -Filter "EXECUSS?ES" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $execussoes) { continue }
        return $execussoes.FullName
    }
    return $null
}

function Resolve-PastaSefaz($raiz) {
    if (-not $raiz) { return $null }
    $sefaz = Get-ChildItem -LiteralPath $raiz -Filter "SEFAZ AUTOMA??O" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sefaz) { return Join-Path $sefaz.FullName "dist\SEFAZ_Site" }
    return $null
}

$raiz = Buscar-Raiz

# Cada sistema guarda a PASTA (nao o .exe direto) porque, antes de rodar, a
# gente copia essa pasta inteira pro disco local (ver comentario mais abaixo,
# perto do botao Executar) - precisa da pasta toda, com o .exe e as DLLs que
# ficam do lado dele, nao so o arquivo do .exe sozinho.
$sistemas = @()
if ($raiz) {
    $sistemas = @(
        [pscustomobject]@{ Nome = "Gerar CND"; Chave = "Gerar_CND"; PastaOrigem = (Join-Path $raiz "CND MUNICIPAL\dist\Gerar_CND"); ExeNome = "Gerar_CND.exe" }
        [pscustomobject]@{ Nome = "DMS Site"; Chave = "DMS_Site"; PastaOrigem = (Join-Path $raiz "PREFEITURA\dist\DMS_Site"); ExeNome = "DMS_Site.exe" }
        [pscustomobject]@{ Nome = "REST Site"; Chave = "REST_Site"; PastaOrigem = (Join-Path $raiz "PREFEITURA\dist\REST_Site"); ExeNome = "REST_Site.exe" }
        [pscustomobject]@{ Nome = "SEFAZ Site"; Chave = "SEFAZ_Site"; PastaOrigem = (Resolve-PastaSefaz $raiz); ExeNome = "SEFAZ_Site.exe" }
        [pscustomobject]@{ Nome = "Malha Fina SEFAZ"; Chave = "Malha_Fina"; PastaOrigem = (Join-Path $raiz "MALHA FINA SEFAZ\dist\Malha_Fina"); ExeNome = "Malha_Fina.exe" }
        [pscustomobject]@{ Nome = "Emissao NFS-e Goiania"; Chave = "Emissao_Nota_Goiania"; PastaOrigem = (Join-Path $raiz "EMITIR NOTAS"); ExeNome = "Emissao_Nota_Goiania.exe" }
        [pscustomobject]@{ Nome = "Emissao Padrao Nacional"; Chave = "Emissao_Padrao_Nacional"; PastaOrigem = (Join-Path $raiz "EMITIR NOTAS"); ExeNome = "Emissao_Padrao_Nacional.exe" }
        [pscustomobject]@{ Nome = "Emissao Portal NFS-e"; Chave = "Emissao_Portal_Nfse"; PastaOrigem = (Join-Path $raiz "EMITIR NOTAS"); ExeNome = "Emissao_Portal_Nfse.exe" }
    )
}

$linkGestor = "https://mqvetkyulrrn3mdltosyu4.streamlit.app/"

# ----------------------------------------------------------------------
# 2) Janela
# ----------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "LUATECH - Executar Sistemas"
$form.Size = New-Object System.Drawing.Size(420, 470)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$lblRaiz = New-Object System.Windows.Forms.Label
if ($raiz) {
    $lblRaiz.Text = "Pasta encontrada: $raiz"
} else {
    $lblRaiz.Text = "AVISO: nao encontrei a pasta AUTOMACAO\PROGRAMAS\EXECUSSOES em nenhuma unidade conhecida (H:, D:\ONEDRIVE, D:, E:, F:, G:, I:, J:, K:). Confirme seu acesso a rede."
}
$lblRaiz.AutoSize = $false
$lblRaiz.Size = New-Object System.Drawing.Size(380, 45)
$lblRaiz.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($lblRaiz)

$checkboxes = New-Object System.Collections.Generic.List[System.Windows.Forms.CheckBox]
$y = 65
foreach ($s in $sistemas) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $s.Nome
    $cb.Tag = $s
    $cb.Location = New-Object System.Drawing.Point(20, $y)
    $cb.Size = New-Object System.Drawing.Size(360, 24)
    $form.Controls.Add($cb)
    $checkboxes.Add($cb)
    $y += 28
}

foreach ($cb in $checkboxes) {
    $cb.Add_CheckedChanged({
        param($sender, $e)
        if ($sender.Checked) {
            foreach ($other in $checkboxes) {
                if ($other -ne $sender -and $other.Checked) { $other.Checked = $false }
            }
        }
    }.GetNewClosure())
}

$btnGestor = New-Object System.Windows.Forms.Button
$btnGestor.Text = "Abrir Gestor Fiscal (site)"
$btnGestor.Location = New-Object System.Drawing.Point(20, $y)
$btnGestor.Size = New-Object System.Drawing.Size(360, 30)
$btnGestor.Add_Click({ Start-Process $linkGestor }.GetNewClosure())
$form.Controls.Add($btnGestor)
$y += 40

$btnExecutar = New-Object System.Windows.Forms.Button
$btnExecutar.Text = "Executar"
$btnExecutar.Location = New-Object System.Drawing.Point(20, $y)
$btnExecutar.Size = New-Object System.Drawing.Size(170, 35)
if (-not $raiz) { $btnExecutar.Enabled = $false }
$form.Controls.Add($btnExecutar)

$btnFechar = New-Object System.Windows.Forms.Button
$btnFechar.Text = "Fechar"
$btnFechar.Location = New-Object System.Drawing.Point(210, $y)
$btnFechar.Size = New-Object System.Drawing.Size(170, 35)
$btnFechar.Add_Click({ $form.Close() }.GetNewClosure())
$form.Controls.Add($btnFechar)

$btnExecutar.Add_Click({
    $selecionado = $checkboxes | Where-Object { $_.Checked } | Select-Object -First 1
    if (-not $selecionado) {
        [System.Windows.Forms.MessageBox]::Show("Marque um sistema antes de clicar em Executar.", "Aviso") | Out-Null
        return
    }
    $sis = $selecionado.Tag
    if (-not $sis.PastaOrigem -or -not (Test-Path -LiteralPath $sis.PastaOrigem)) {
        [System.Windows.Forms.MessageBox]::Show("Nao encontrei a pasta de '$($sis.Nome)'. Confirme com o suporte se o caminho mudou.", "Erro") | Out-Null
        return
    }

    # Antes de abrir, copia a pasta do sistema (o .exe e as DLLs do lado
    # dele) pra um cache local do usuario, via robocopy (so copia o que
    # mudou desde a ultima vez - rapido depois da primeira execucao). Isso
    # evita rodar o .exe direto pela rede, que fica bem lento (cada um dos
    # varios arquivos internos precisa ser lido pela rede e escaneado pelo
    # antivirus). O .exe roda igual estando na copia local, sem precisar de
    # nenhum ajuste - ele acha sozinho suas dependencias do lado dele.
    $pastaLocal = Join-Path $env:LOCALAPPDATA "LUATECH\$($sis.Chave)"
    $textoOriginal = $btnExecutar.Text
    $btnExecutar.Enabled = $false
    $btnExecutar.Text = "Preparando..."
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    [System.Windows.Forms.Application]::DoEvents()

    New-Item -ItemType Directory -Path $pastaLocal -Force -ErrorAction SilentlyContinue | Out-Null
    $argsRobocopy = @("$($sis.PastaOrigem)", "$pastaLocal", "/MIR", "/R:1", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS")
    $procRobocopy = Start-Process -FilePath "robocopy.exe" -ArgumentList $argsRobocopy -NoNewWindow -Wait -PassThru
    $codigoRobocopy = $procRobocopy.ExitCode

    $btnExecutar.Text = $textoOriginal
    $btnExecutar.Enabled = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::Default

    # Codigos do robocopy: 0-7 sao variacoes de sucesso, 8+ e erro de
    # verdade. Se der erro na copia, cai pra rodar direto da rede (mais
    # lento, mas ainda funciona) em vez de travar o usuario.
    if ($codigoRobocopy -ge 8) {
        [System.Windows.Forms.MessageBox]::Show("Nao consegui copiar os arquivos de '$($sis.Nome)' pra pasta local (codigo robocopy $codigoRobocopy). Vou tentar abrir direto da rede - pode demorar mais.", "Aviso") | Out-Null
        $exeAlvo = Join-Path $sis.PastaOrigem $sis.ExeNome
    } else {
        $exeAlvo = Join-Path $pastaLocal $sis.ExeNome
    }

    if (-not (Test-Path -LiteralPath $exeAlvo)) {
        [System.Windows.Forms.MessageBox]::Show("Nao encontrei o arquivo '$($sis.ExeNome)'. Confirme com o suporte se o caminho mudou.", "Erro") | Out-Null
        return
    }
    Start-Process -FilePath $exeAlvo
    [System.Windows.Forms.MessageBox]::Show("'$($sis.Nome)' foi aberto - acompanhe a janela que apareceu.", "Pronto") | Out-Null
}.GetNewClosure())

[void]$form.ShowDialog()
