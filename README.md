# Dotfiles: Nix + Home Manager

Gerenciamento declarativo e reprodutível de ambiente de desenvolvimento pessoal (WSL / Linux) utilizando Nix Flakes e Home Manager.

Este repositório armazena centralizadamente todas as configurações de shell, variáveis de ambiente, aliases, interface gráfica do terminal (prompt) e ferramentas CLI, aplicando conceitos de Infraestrutura como Código (IaC) para garantir consistência absoluta entre múltiplas máquinas.

---

## Estrutura do Repositório

* `flake.nix`: O maestro da configuração. Define as fontes dos pacotes (canais do Nix) e os perfis das máquinas alvo (mapeados por usuário).
* `home.nix`: A receita do ambiente pessoal. Declara os pacotes a serem instalados, os aliases do Bash, o prompt do shell e as configurações de integração.
* `flake.lock`: Arquivo gerado automaticamente pelo Nix que grava as versões exatas de todas as dependências, garantindo a reprodutibilidade.

---

## Ferramentas e Pacotes Gerenciados

O ambiente está configurado com um ecossistema moderno de ferramentas de terminal voltadas para produtividade e automação:

* **Customização do Prompt**: Starship (prompt cross-shell ultrarrápido escrito em Rust, exibindo diretório, branch e status do Git).
* **Toolkit CLI**: `bat` (substituto do `cat`), `eza` (substituto do `ls` com suporte a ícones), `zoxide` (navegação inteligente de diretórios), `fzf` (busca fuzzy interativa), `ripgrep` (buscas rápidas em código) e `fd` (busca otimizada de arquivos).
* **Processamento de Dados**: `jq` (JSON) e `yq` (YAML) para manipulação de manifestos e configurações de CI/CD.
* **Orquestração e SCM**: `lazygit` (interface de terminal para Git) e `lazydocker` (interface de terminal para gerenciamento de contêineres).
* **Base do Sistema**: `git`, `htop` e ferramentas GNU padrão.
* **Linguagens e Ecossistemas (Nativamente via Nix)**:
  * **Java**: JDK 25 LTS, Maven, Gradle, JDT Language Server e Google Java Format.
  * **PHP**: PHP 8.5, Composer e Intelephense.
  * **Python**: Python 3, Poetry, Pyright e Ruff.
  * **Node.js/React**: Node, Yarn, pnpm, TS Language Server e Prettier.

---

## Aliases Configurados

* **Workspaces UERJ (VS Code e Antigravity IDE)**:
  * `uws`: Menu interativo (`fzf`) para selecionar e abrir qualquer workspace da UERJ no VS Code (ex: `uws`).
  * `uws <termo>`: Abre diretamente o workspace cujo nome contenha o termo buscado (ex: `uws assiste`, `uws euerj`, `uws spo`).
  * `uws -a <termo>`: Abre diretamente no **Antigravity IDE** forçando o modo remoto WSL (ex: `uws -a spo`).
  * `ws-list`: Lista todos os workspaces `.code-workspace` disponíveis de forma limpa.
  * `ws-uerj`: Navega diretamente para o diretório `~/.dotfiles-uerj/workspaces/vscode`.
* **Nix & Home Manager**:
  * `hms`: Aplica as configurações do Nix (`home-manager switch --flake ...`).
  * `hmn`: Lê as notas de atualização do Nix.
  * `hmg`: Lista as gerações (versões) anteriores do ambiente.
  * `nfu`: Atualiza o arquivo `flake.lock` (`nix flake update ...`).
  * `nix-gc`: Faz a limpeza de lixo do Nix para liberar espaço em disco.
* **Git Avançado**:
  * `st`: Atalho rápido para `git status`.
  * `gfp`: Busca atualizações e limpa referências remotas obsoletas (`git fetch --prune`).
  * `glog`: Plota a árvore dos últimos 20 commits de forma limpa.
  * `gclean-gone` e `gclean-merged`: Scripts automatizados para deleção de branches locais que já foram mescladas ou apagadas no repositório remoto.
* **Docker e Laravel**:
  * `art` e `pest`: Encapsulam a execução do Artisan e do framework Pest diretamente no contêiner da API.
  * `dreset`: Executa o fluxo completo de recriação de contêineres e scripts de setup local.
  * `dtest`: Aciona a suíte de testes do pipeline local.

---

## Configuração em uma Nova Máquina

Siga os passos abaixo para replicar exatamente este ambiente em um novo PC com Windows 11 (WSL2) ou Linux nativo.

### Requisitos Prévios

1. **WSL2 instalado** (se estiver no Windows) com uma distribuição Linux funcional (ex: Ubuntu 24.04 / 26.04).
2. **Acesso à Internet** para baixar o instalador e os pacotes do cache do Nix.
3. **Git instalado** na máquina para clonar o repositório (`sudo apt update && sudo apt install -y git`).
4. **Fonte Nerd Font instalada** (Recomendado: *MesloLGS NF*) configurada no seu emulador de terminal (ou VS Code) para que os ícones do Starship e do Eza funcionem corretamente.

---

### Passo a Passo de Instalação

#### 1. Instalar o Nix (Via Determinate Systems)

O instalador da Determinate Systems configura automaticamente os Flakes e gerencia o daemon do Nix de forma limpa no WSL.

```bash
URL="https://install.determinate.systems/nix"
curl --proto '=https' --tlsv1.2 -sSf -L "$URL" | sh -s -- install
```

> **Nota:** Siga as instruções exibidas no terminal. Ao finalizar, feche e abra um novo terminal (ou execute `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`) para carregar o ambiente do Nix na sessão atual.

---

#### 2. Configurar Chaves SSH para o GitHub (Pessoal e Trabalho)

Em uma instalação recém-criada do WSL, o diretório `~/.ssh` ainda não existe. Para gerenciar múltiplas contas (ex: **Pessoal** e **Trabalho**) de forma organizada e sem conflitos, crie arquivos de chaves separados e use o `~/.ssh/config`:

1. **Garantir a criação do diretório `.ssh`:**
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   ```

2. **Gerar as chaves SSH (algoritmo Ed25519):**
   * **Chave Pessoal:**
     ```bash
     ssh-keygen -t ed25519 -C "seu_email_pessoal@exemplo.com" -f ~/.ssh/id_ed25519_pessoal
     ```
   * **Chave de Trabalho:**
     ```bash
     ssh-keygen -t ed25519 -C "seu_email_trabalho@empresa.com" -f ~/.ssh/id_ed25519_trabalho
     ```
   *(Pressione `Enter` para prosseguir e defina uma senha/passphrase se desejar)*

3. **Iniciar o SSH Agent e adicionar as chaves privadas:**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519_pessoal
   ssh-add ~/.ssh/id_ed25519_trabalho
   ```

4. **Configurar o arquivo `~/.ssh/config`:**
   Crie ou edite o arquivo de configuração para mapear automaticamente qual chave usar para cada host:
   ```bash
   cat << 'EOF' > ~/.ssh/config
   # detalhes em https://linuxize.com/post/using-the-ssh-config-file/#quick-reference

   # Conta Pessoal (Padrão para github.com)
   Host github.com
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_pessoal
       IdentitiesOnly yes

   # Conta de Trabalho
   Host github-work
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_trabalho
       IdentitiesOnly yes
   EOF
   chmod 600 ~/.ssh/config
   ```

5. **Exibir e cadastrar as chaves públicas no GitHub:**
   * Exibir chave **pessoal**:
     ```bash
     cat ~/.ssh/id_ed25519_pessoal.pub
     ```
   * Exibir chave de **trabalho**:
     ```bash
     cat ~/.ssh/id_ed25519_trabalho.pub
     ```
   * *Acesse cada conta no GitHub em **Settings > SSH and GPG keys > New SSH key** (ou [github.com/settings/ssh/new](https://github.com/settings/ssh/new)) e adicione a respectiva chave pública.*

6. **Validar as conexões:**
   * Testar conexão pessoal:
     ```bash
     ssh -T git@github.com
     ```
   * Testar conexão de trabalho:
     ```bash
     ssh -T git@github-work
     ```
   *(Digite `yes` na primeira vez para confiar no host. A resposta confirmará o usuário autenticado em cada conta)*

---

#### 3. Clonar este Repositório

Com a chave SSH configurada e autorizada no GitHub, clone o repositório diretamente na pasta `~/.dotfiles`:

```bash
git clone git@github.com:alexandredct/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

---

#### 4. Ajustar o Nome do Usuário (Se necessário)

Se o nome do usuário Linux da nova máquina for diferente do configurado atualmente (`alexandre`):
* Verifique o seu usuário atual rodando: `whoami`
* Atualize o campo correspondente no arquivo `flake.nix` e no `home.nix`.

---

#### 5. Rodar a Primeira Compilação (Bootstrap)

O Nix lerá o Flake local, baixará as ferramentas declaradas e criará os links simbólicos, fazendo o backup de arquivos conflitantes pré-existentes (como o `.bashrc` padrão):

```bash
nix run home-manager/master -- switch --flake .#alexandre -b backup
```
*(Substitua `alexandre` pelo seu nome de usuário caso seja diferente)*

---

#### 6. Recarregar o Shell

Para que as novas ferramentas (como o *zoxide*), o novo prompt (*Starship*) e todos os aliases entrem em vigor imediatamente:

```bash
exec bash
```

---

## Dica de Configuração: Ícones Quebrados no Terminal do VS Code

Se você estiver utilizando o VS Code no Windows conectado ao WSL e notar caracteres não reconhecidos (como `` ou caixinhas de interrogação), certifique-se de configurar a fonte correta:

1. Instale a fonte **MesloLGS NF** no Windows.
2. No VS Code, abra as Configurações (`Ctrl + ,`).
3. Busque por `terminal font`.
4. Defina o campo **Terminal > Integrated: Font Family** como `'MesloLGS NF'` (com as aspas simples).
5. Reinicie o terminal do VS Code.

---

## Fluxo de Trabalho Diário

Sempre que desejar adicionar um novo pacote, criar um alias ou alterar uma configuração:

1. Abra o arquivo `~/.dotfiles/home.nix` e faça as alterações necessárias.
2. Adicione as modificações ao staging area do Git:

    ```bash
    git add home.nix
    ```

3. Aplique a nova configuração através do alias configurado:

    ```bash
    hms
    ```

4. Realize o commit (incluindo o `flake.lock` se houver mudanças de dependências) e envie para o repositório remoto:

    ```bash
    git commit -m "feat: atualiza configuracoes do ambiente"
    git push
    ```
