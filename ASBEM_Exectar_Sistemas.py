# ============================================================================
# EXECUTE OS SISTEMAS - LUATECH / ASBEM
# Painel de rede para abrir os sistemas locais do escritório.
# ============================================================================

import streamlit as st
import subprocess
import os
import threading
import time
from pathlib import Path

# ============================================================================
# CONFIGURAÇÕES INICIAIS
# ============================================================================

st.set_page_config(page_title="LUATECH - ASBEM - EXECUTE OS SISTEMAS", layout="wide")

BASE_DIR = Path(os.path.abspath(__file__)).parent
LOGO_PATH = BASE_DIR / "logo_luatech.ico"

# Limite de linhas de log guardadas por execução — evita crescer sem fim numa
# run de horas (ex: SEFAZ Site, que pode ficar rodando por até 5h).
MAX_LINHAS_LOG = 5000

# Sistemas locais disponíveis para execução.
# Pasta compartilhada na rede da empresa — só máquinas com acesso a essa pasta
# do servidor conseguem rodar os sistemas abaixo (movido de "SISTEMAS PARA
# LUATECH", em disco local, para cá em 03/08/2026).
PASTA_SISTEMAS = r"D:\ONEDRIVE\AUTOMAÇÃO\PROGRAMAS\EXECUSSÕES"

# Desde 20/08/2026: cada sistema é um .exe compilado (PyInstaller --onedir),
# não mais um .py — a máquina que hospeda este launcher (192.168.1.250) não
# tem Python instalado, então não dá pra chamar "python script.py". Cada
# caminho abaixo aponta pro .exe dentro da sua própria pasta onedir (o
# _internal ao lado dele tem as dependências, não mexer separado do exe).
SISTEMAS = {
    "Gerar CND": PASTA_SISTEMAS + r"\CND MUNICIPAL\Gerar_CND.exe",
    "DMS Site": PASTA_SISTEMAS + r"\PREFEITURA\DMS_Site.exe",
    "REST Site": PASTA_SISTEMAS + r"\PREFEITURA\REST SITE\REST_Site.exe",
    "SEFAZ Site": PASTA_SISTEMAS + r"\SEFAZ AUTOMAÇÃO\SEFAZ_Site.exe",
    "Malha Fina SEFAZ": PASTA_SISTEMAS + r"\MALHA FINA SEFAZ\Malha_Fina.exe",
}

# ============================================================================
# CSS
# ============================================================================

st.markdown("""
<style>
.menu-btn button {
    width: 100%;
    height: 110px;
    font-size: 22px !important;
    font-weight: bold !important;
    border-radius: 12px !important;
    border: 2px solid #1d3f77 !important;
    background-color: #1d3f77 !important;
    color: white !important;
    cursor: pointer;
    transition: background-color 0.2s;
}
.menu-btn button:hover {
    background-color: #163066 !important;
}
</style>
""", unsafe_allow_html=True)

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

def _ler_saida_processo(estado: dict):
    """Roda em thread separada: lê a saída (stdout+stderr) do processo linha a
    linha e guarda em estado['linhas'] pra pagina_sistemas() exibir ao vivo no
    próximo rerun. Não chama nenhuma função st.* aqui dentro — só mexe num
    dicionário Python comum, que a thread principal do Streamlit é quem lê."""
    for linha in iter(estado["processo"].stdout.readline, ""):
        estado["linhas"].append(linha.rstrip("\n"))
        if len(estado["linhas"]) > MAX_LINHAS_LOG:
            del estado["linhas"][:len(estado["linhas"]) - MAX_LINHAS_LOG]

    codigo = estado["processo"].wait()
    estado["codigo_saida"] = codigo
    estado["status"] = "concluido" if codigo == 0 else "erro"


def executar_sistema(nome: str, caminho: str):
    if not os.path.exists(caminho):
        st.error(f"Arquivo não encontrado: {caminho}")
        return

    execucoes = st.session_state.setdefault("execucoes", {})
    existente = execucoes.get(nome)
    if existente and existente["processo"].poll() is None:
        st.warning(f"'{nome}' já está rodando — acompanhe o log abaixo antes de rodar de novo.")
        return

    try:
        processo = subprocess.Popen(
            [caminho],  # .exe compilado — não passa mais por sys.executable
            cwd=os.path.dirname(caminho),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
    except Exception as e:
        st.error(f"Erro ao executar: {e}")
        return

    estado = {"processo": processo, "linhas": [], "status": "rodando", "codigo_saida": None}
    execucoes[nome] = estado
    threading.Thread(target=_ler_saida_processo, args=(estado,), daemon=True).start()
    st.toast(f"'{nome}' iniciado — acompanhe o log logo abaixo.", icon="✅")

# ============================================================================
# SIDEBAR
# ============================================================================

if LOGO_PATH.exists():
    st.sidebar.image(str(LOGO_PATH), use_container_width=True)

st.sidebar.markdown("<h3 style='text-align:center; color:#1d3f77;'>ASBEM</h3>", unsafe_allow_html=True)
st.sidebar.markdown("<hr style='margin: 8px 0;'>", unsafe_allow_html=True)

# ============================================================================
# CABEÇALHO
# ============================================================================

st.markdown("<p style='color:#1d3f77; font-size:18px; font-weight:600; margin-bottom:0;'>ASBEM</p>", unsafe_allow_html=True)
st.markdown("<h1 style='color:#1d3f77; margin-top:0;'>EXECUTE OS SISTEMAS</h1>", unsafe_allow_html=True)

st.markdown("<hr>", unsafe_allow_html=True)

# ============================================================================
# PÁGINA: SISTEMAS
# ============================================================================

def pagina_sistemas():
    st.caption("Sistemas de teste — lista provisória, ainda será ajustada.")

    if not SISTEMAS:
        st.info("Nenhum sistema cadastrado ainda.")
        return

    nomes = list(SISTEMAS.keys())
    colunas = st.columns(4)
    for i, nome in enumerate(nomes):
        with colunas[i % 4]:
            st.markdown('<div class="menu-btn">', unsafe_allow_html=True)
            if st.button(nome, use_container_width=True, key=f"btn_sistema_{nome}"):
                executar_sistema(nome, SISTEMAS[nome])
            st.markdown('</div>', unsafe_allow_html=True)

    execucoes = st.session_state.get("execucoes", {})
    algum_rodando = False
    if execucoes:
        st.markdown("<hr>", unsafe_allow_html=True)
        st.subheader("Log de execução")
        for nome, estado in execucoes.items():
            status = estado["status"]
            if status == "rodando":
                algum_rodando = True
                rotulo_status = "🟢 rodando..."
            elif status == "concluido":
                rotulo_status = "✅ concluído"
            else:
                rotulo_status = f"❌ erro (código de saída {estado['codigo_saida']})"

            with st.expander(f"{nome} — {rotulo_status}", expanded=(status == "rodando")):
                texto_log = "\n".join(estado["linhas"][-300:]) or "(sem saída ainda)"
                st.code(texto_log, language=None)

    if algum_rodando:
        time.sleep(2)
        st.rerun()

# ============================================================================
# ROTEAMENTO
# ============================================================================

pagina_sistemas()
