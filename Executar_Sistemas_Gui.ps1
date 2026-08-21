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

function Resolve-ExeSefaz($raiz) {
    if (-not $raiz) { return $null }
    $sefaz = Get-ChildItem -LiteralPath $raiz -Filter "SEFAZ AUTOMA??O" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sefaz) { return Join-Path $sefaz.FullName "dist\SEFAZ_Site\SEFAZ_Site.exe" }
    return $null
}

$raiz = Buscar-Raiz

$sistemas = @()
if ($raiz) {
    $sistemas = @(
        [pscustomobject]@{ Nome = "Gerar CND"; Exe = (Join-Path $raiz "CND MUNICIPAL\dist\Gerar_CND\Gerar_CND.exe") }
        [pscustomobject]@{ Nome = "DMS Site"; Exe = (Join-Path $raiz "PREFEITURA\dist\DMS_Site\DMS_Site.exe") }
        [pscustomobject]@{ Nome = "REST Site"; Exe = (Join-Path $raiz "PREFEITURA\dist\REST_Site\REST_Site.exe") }
        [pscustomobject]@{ Nome = "SEFAZ Site"; Exe = (Resolve-ExeSefaz $raiz) }
        [pscustomobject]@{ Nome = "Malha Fina SEFAZ"; Exe = (Join-Path $raiz "MALHA FINA SEFAZ\dist\Malha_Fina\Malha_Fina.exe") }
        [pscustomobject]@{ Nome = "Emissao NFS-e Goiania"; Exe = (Join-Path $raiz "EMITIR NOTAS\Emissao_Nota_Goiania.exe") }
        [pscustomobject]@{ Nome = "Emissao Padrao Nacional"; Exe = (Join-Path $raiz "EMITIR NOTAS\Emissao_Padrao_Nacional.exe") }
        [pscustomobject]@{ Nome = "Emissao Portal NFS-e"; Exe = (Join-Path $raiz "EMITIR NOTAS\Emissao_Portal_Nfse.exe") }
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
    if (-not $sis.Exe -or -not (Test-Path -LiteralPath $sis.Exe)) {
        [System.Windows.Forms.MessageBox]::Show("Nao encontrei o arquivo de '$($sis.Nome)'. Confirme com o suporte se o caminho mudou.", "Erro") | Out-Null
        return
    }
    Start-Process -FilePath $sis.Exe
    [System.Windows.Forms.MessageBox]::Show("'$($sis.Nome)' foi aberto - acompanhe a janela que apareceu.", "Pronto") | Out-Null
}.GetNewClosure())

[void]$form.ShowDialog()
