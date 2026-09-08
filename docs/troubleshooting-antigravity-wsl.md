# Troubleshooting & Arquitetura: Antigravity IDE / VS Code Server no WSL

Este guia documenta os aprendizados de integração entre o **Antigravity IDE** (ou VS Code), o subsistema **WSL 2** e o gerenciador de pacotes **Nix / Home Manager**, cobrindo causas-raiz de falhas comuns em novas instâncias e soluções recomendadas.

---

## 1. Arquitetura de Execução Remota no WSL

O modelo de desenvolvimento remoto com WSL segue uma arquitetura cliente-servidor:

```mermaid
graph LR
    subgraph Windows ["Host Windows"]
        Client["Antigravity IDE (GUI / Electron)"]
        ExtWSL["Extensão Remote WSL"]
    end

    subgraph WSL ["Ambiente WSL (ex: Ubuntu 26.04)"]
        Server["Antigravity IDE Server (Node.js headless)"]
        Tools["Nix / Home Manager / Git / Compiladores"]
        Workspace["~/workspace/..."]
    end

    Client <--> ExtWSL
    ExtWSL -- "IPC / Sockets (localhost:porta)" --> Server
    Server --> Tools
    Server --> Workspace
```

- **No Windows:** Roda a interface gráfica (Electron), renderização e atalhos.
- **No WSL:** Roda um servidor Node.js headless (`antigravity-ide-server`), localizado em `~/.antigravity-ide-server/bin/<versao>-<commit>/`.
- **Comunicação:** O cliente Windows se conecta ao servidor dentro do WSL via porta local segura com token (`.installation_lock` / `.token`).

---

## 2. Problemas Comuns e Causas-Raiz

### A. Falha no Download Automático do Servidor (`Error downloading server from all URLs`)

#### Sintoma:
Ao tentar conectar pelo Windows, surge o erro modal:
> *Could not establish connection to WSL distro "Ubuntu-26.04"*
> *Error: installation failed. exitCode==1==*
> *Download failed from https://redirector.gvt1.com/.../Antigravity%20IDE-reh.tar.gz*

#### Causa-Raiz:
A extensão `antigravity-remote-wsl` roda um script Bash no WSL que tenta usar `wget` para baixar o pacote do servidor do Google CDN (`edgedl.me.gvt1.com` ou `redirector.gvt1.com`). Em novas distros:
1. Podem faltar certificados de CA atualizados (`ca-certificates`).
2. O CDN do Google retorna **HTTP 404** se o artefato público correspondente ao commit específico do cliente Windows não estiver aberto para download anônimo sem token na rota padrão.
3. Se o script falhar, um arquivo vazio `~/.antigravity-ide-server/.installation_lock` pode permanecer no disco, bloqueando tentativas subsequentes.

#### Solução:
- **Limpeza de Locks:**
  ```bash
  rm -rf ~/.antigravity-ide-server
  ```
- **Instalação Manual / Cópia dos Binários:**
  Como o servidor é puramente empacotado em `~/.antigravity-ide-server/bin/<versao>-<commit>`, é possível reutilizar os binários compilados de uma instalação funcional compactando e extraindo a pasta correspondente:
  ```bash
  # Extração direta no WSL:
  mkdir -p ~/.antigravity-ide-server/bin
  tar -xzf antigravity-server-<versao>.tar.gz -C ~/.antigravity-ide-server/bin/
  ```

---

### B. Prompt Interativo do VS Code no Home Manager (`DONT_PROMPT_WSL_INSTALL`)

#### Sintoma:
Ao rodar a ativação do Home Manager (`nix run home-manager/master -- switch ...`), o terminal pausa com a seguinte mensagem interativa:
> *To use Visual Studio Code with the Windows Subsystem for Linux, please install Visual Studio Code in Windows and uninstall the Linux version in WSL.*
> *Do you want to continue anyway? [y/N]*

#### Causa-Raiz:
A presença do módulo `programs.vscode` gerenciado pelo Nix tenta configurar os perfis de extensões no Linux. Ao detectar o WSL, o script de ativação do Home Manager solicita confirmação manual do usuário para não sobrepor o binário do Windows.

#### Solução:
Definir a variável de ambiente `DONT_PROMPT_WSL_INSTALL = "1"` nas variáveis de sessão globais do Home Manager ([home.nix](file:///home/alexandre/.dotfiles/home.nix)):
```nix
home.sessionVariables = {
  DONT_PROMPT_WSL_INSTALL = "1";
};
```
Isso desativa a interrupção interativa e permite automação completa (CI/CD ou scripts sem intervenção).

---

### C. Nome da Distro Hardcoded na Função de Atalho (`agy`)

#### Sintoma:
Ao executar o comando `agy .` em uma máquina com uma versão diferente do Ubuntu (ex: `Ubuntu-26.04`), o IDE tenta se conectar à distribuição antiga (`ubuntu-24.04`) ou abre um arquivo local no Windows com erro de autoridade remota.

#### Causa-Raiz:
O atalho usava a URI fixa:
`vscode-remote://wsl+ubuntu-24.04$abs_path`

#### Solução:
Usar a variável de ambiente nativa injetada pelo próprio WSL, `$WSL_DISTRO_NAME`:
```bash
local distro="${WSL_DISTRO_NAME:-Ubuntu-26.04}"
"$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" --new-window "$uri_flag" "vscode-remote://wsl+$distro$abs_path"
```

---

## 3. Checklist de Preparação de uma Nova Máquina WSL

Ao subir uma nova distribuição WSL (ex: `Ubuntu-26.04`):

1. **Dependências Mínimas do Sistema Operacional:**
   ```bash
   sudo apt update && sudo apt install -y curl wget ca-certificates tar gzip bzip2 xz-utils procps
   ```

2. **Instalação do Nix (Single-User ou Multi-User):**
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --no-daemon
   ```

3. **Clonagem dos Dotfiles e Ativação:**
   ```bash
   git clone git@github.com:alexandredct/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   nix run home-manager/master -- switch --flake .#alexandre -b backup
   ```

4. **Recarregamento da Sessão:**
   ```bash
   exec bash
   ```

5. **Abertura do Workspace no Antigravity IDE:**
   ```bash
   agy ~/workspace
   ```
