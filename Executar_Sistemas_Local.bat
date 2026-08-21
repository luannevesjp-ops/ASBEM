@echo off
REM ============================================================================
REM EXECUTAR SISTEMAS - LUATECH / ASBEM (tela grafica local, sem servidor)
REM
REM Arquivo simples, sem nenhum truque de codificacao/arquivo escondido (a
REM versao anterior gerava um script na hora via certutil -decode, mas isso
REM e um padrao classico de virus/malware e antivirus passou a bloquear -
REM por isso agora sao DOIS arquivos de texto puro, sem nada disfarcado:
REM este .bat e o Executar_Sistemas_Gui.ps1, que precisam ficar SEMPRE
REM JUNTOS na mesma pasta (por isso a distribuicao e em .zip).
REM
REM Este .bat so abre a tela grafica (PowerShell + Windows Forms - ja vem em
REM qualquer Windows, nao precisa instalar nada). A tela acha sozinha a
REM pasta de rede compartilhada (letra de unidade varia por PC).
REM
REM Distribuido pelo botao "EXECUTAR SISTEMAS" do Gestor Fiscal, como um
REM .zip com os dois arquivos - o usuario extrai o .zip inteiro (sem separar
REM os arquivos) e roda este .bat.
REM
REM Sem acento nos textos deste arquivo de proposito: arquivo .bat depende da
REM "code page" do Windows de cada PC pra mostrar acento certo, e isso varia
REM de maquina pra maquina.
REM ============================================================================

set "PASTA_AQUI=%~dp0"
set "PS1=%PASTA_AQUI%Executar_Sistemas_Gui.ps1"

if not exist "%PS1%" (
    echo.
    echo Nao encontrei o arquivo Executar_Sistemas_Gui.ps1 nesta pasta:
    echo %PASTA_AQUI%
    echo.
    echo Os dois arquivos - este .bat e o .ps1 - precisam estar juntos na
    echo mesma pasta - confirme se extraiu o .zip inteiro, sem separar
    echo os arquivos.
    echo.
    pause
    exit /b 1
)

start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"
exit /b 0
