@echo off
REM ============================================================================
REM EXECUTAR SISTEMAS - LUATECH / ASBEM (versao local, sem servidor)
REM
REM Arquivo leve, sem instalacao nenhuma. Roda os sistemas (.exe ja
REM compilados) DIRETO na maquina de quem clicar, lendo da pasta de rede
REM compartilhada (a mesma pasta "AUTOMACAO\PROGRAMAS" que todo mundo ja
REM tem acesso - so muda a letra de unidade de PC pra PC: a maioria ve como
REM H:, uma maquina especifica ve como D:\ONEDRIVE, outras podem ver com
REM outra letra ainda).
REM
REM Por isso este arquivo NAO assume uma letra fixa: ele procura a pasta em
REM varias letras conhecidas ate achar uma que exista naquela maquina. Se no
REM futuro aparecer um PC com outra letra ainda, so adicionar mais uma linha
REM na lista CANDIDATOS_RAIZ abaixo.
REM
REM Pode ser copiado pra qualquer PC (area de trabalho, pen drive, etc) - nao
REM precisa estar dentro da pasta de rede pra funcionar. Distribuido pelo
REM botao "EXECUTAR SISTEMAS" do Gestor Fiscal (cada usuario baixa o seu).
REM
REM Sem acento nos textos deste arquivo de proposito: arquivo .bat depende da
REM "code page" do Windows de cada PC pra mostrar acento certo, e isso varia
REM de maquina pra maquina. Acento so em nome de pasta real (resolvido via
REM curinga "?", nunca digitado direto), nunca em texto solto do menu.
REM ============================================================================

setlocal EnableDelayedExpansion
title LUATECH - Executar Sistemas (local)
cd /d %~dp0

REM ----------------------------------------------------------------------
REM 1) Achar a pasta EXECUSSOES, testando varias raizes conhecidas em ordem
REM    de prioridade (H: primeiro, por ser a maioria; D:\ONEDRIVE depois,
REM    que e onde da pra testar por enquanto).
REM ----------------------------------------------------------------------
set "RAIZ="

for /d %%T in (
    "H:\AUTOMA??O"
    "D:\ONEDRIVE\AUTOMA??O"
    "D:\AUTOMA??O"
    "E:\AUTOMA??O"
    "F:\AUTOMA??O"
    "G:\AUTOMA??O"
    "I:\AUTOMA??O"
    "J:\AUTOMA??O"
    "K:\AUTOMA??O"
) do (
    if not defined RAIZ (
        for /d %%B in ("%%T\PROGRAMAS") do (
            for /d %%C in ("%%B\EXECUSS?ES") do (
                set "RAIZ=%%C"
            )
        )
    )
)

if not defined RAIZ (
    echo.
    echo Nao encontrei a pasta AUTOMACAO\PROGRAMAS\EXECUSSOES em nenhuma
    echo unidade conhecida deste PC ^(H:, D:\ONEDRIVE, D:, E:, F:, G:, I:, J:, K:^).
    echo.
    echo Confirme se este PC tem acesso a pasta compartilhada da rede
    echo ^(normalmente aparece como H: no "Meu Computador"^) e tente de novo.
    echo Se a letra for outra, avise o suporte pra atualizar este arquivo.
    echo.
    pause
    exit /b 1
)

REM ----------------------------------------------------------------------
REM 2) Montar o caminho de cada sistema (mesma estrutura de pastas que o
REM    painel central usa - ver SISTEMAS em ASBEM_Exectar_Sistemas.py).
REM    "SEFAZ AUTOMACAO" tem acento real na pasta, por isso resolve por
REM    curinga em vez de escrever direto.
REM ----------------------------------------------------------------------
set "EXE_CND=%RAIZ%\CND MUNICIPAL\dist\Gerar_CND\Gerar_CND.exe"
set "EXE_DMS=%RAIZ%\PREFEITURA\dist\DMS_Site\DMS_Site.exe"
set "EXE_REST=%RAIZ%\PREFEITURA\dist\REST_Site\REST_Site.exe"
set "EXE_MALHA=%RAIZ%\MALHA FINA SEFAZ\dist\Malha_Fina\Malha_Fina.exe"
set "EXE_NOTAGO=%RAIZ%\EMITIR NOTAS\Emissao_Nota_Goiania.exe"
set "EXE_NOTAPADRAO=%RAIZ%\EMITIR NOTAS\Emissao_Padrao_Nacional.exe"
set "EXE_NOTAPORTAL=%RAIZ%\EMITIR NOTAS\Emissao_Portal_Nfse.exe"

set "EXE_SEFAZ="
for /d %%S in ("%RAIZ%\SEFAZ AUTOMA??O") do (
    set "EXE_SEFAZ=%%S\dist\SEFAZ_Site\SEFAZ_Site.exe"
)

REM Link do Gestor Fiscal (site na nuvem) - so pra dar um atalho de volta,
REM nao tem nenhuma dependencia da pasta de rede.
set "LINK_GESTOR=https://mqvetkyulrrn3mdltosyu4.streamlit.app/"

REM ----------------------------------------------------------------------
REM 3) Menu
REM ----------------------------------------------------------------------
:menu
cls
echo ============================================================
echo   LUATECH - EXECUTAR SISTEMAS (local)
echo   Pasta encontrada em: %RAIZ%
echo ============================================================
echo.
echo   1 - Gerar CND
echo   2 - DMS Site
echo   3 - REST Site
echo   4 - SEFAZ Site
echo   5 - Malha Fina SEFAZ
echo   6 - Emissao NFS-e Goiania
echo   7 - Emissao Padrao Nacional
echo   8 - Emissao Portal NFS-e
echo   9 - Abrir Gestor Fiscal (site)
echo   0 - Sair
echo.
set "ESCOLHA="
set /p ESCOLHA=Digite o numero e pressione ENTER:

if "%ESCOLHA%"=="1" call :abrir "%EXE_CND%" "Gerar CND"
if "%ESCOLHA%"=="2" call :abrir "%EXE_DMS%" "DMS Site"
if "%ESCOLHA%"=="3" call :abrir "%EXE_REST%" "REST Site"
if "%ESCOLHA%"=="4" call :abrir "%EXE_SEFAZ%" "SEFAZ Site"
if "%ESCOLHA%"=="5" call :abrir "%EXE_MALHA%" "Malha Fina SEFAZ"
if "%ESCOLHA%"=="6" call :abrir "%EXE_NOTAGO%" "Emissao NFS-e Goiania"
if "%ESCOLHA%"=="7" call :abrir "%EXE_NOTAPADRAO%" "Emissao Padrao Nacional"
if "%ESCOLHA%"=="8" call :abrir "%EXE_NOTAPORTAL%" "Emissao Portal NFS-e"
if "%ESCOLHA%"=="9" start "" "%LINK_GESTOR%"
if "%ESCOLHA%"=="0" exit /b 0

goto menu

REM ----------------------------------------------------------------------
REM :abrir <caminho_exe> <nome_amigavel>
REM ----------------------------------------------------------------------
:abrir
set "ALVO=%~1"
set "NOME=%~2"
if not defined ALVO (
    echo.
    echo Nao encontrei a pasta de "%NOME%" dentro de %RAIZ%.
    echo Confirme com o suporte se o caminho mudou.
    echo.
    pause
    goto :eof
)
if not exist "%ALVO%" (
    echo.
    echo Arquivo nao encontrado: %ALVO%
    echo.
    pause
    goto :eof
)
echo.
echo Abrindo %NOME% ...
start "" "%ALVO%"
echo Pronto - acompanhe a janela que abriu.
echo.
pause
goto :eof
