# Dotfiles: Nix + Home Manager

Gerenciamento declarativo e reprodutível de ambiente de desenvolvimento pessoal (WSL / Linux) utilizando Nix Flakes e Home Manager.

Este repositório armazena centralizadamente todas as configurações de shell, variáveis de ambiente, aliases e ferramentas CLI, aplicando conceitos de Infraestrutura como Código (IaC) para garantir consistência absoluta entre múltiplas máquinas.

---

## Estrutura do Repositório

* flake.nix: O maestro da configuração. Define as fontes dos pacotes (canais do Nix) e os perfis das máquinas alvo (mapeados por usuário).
* home.nix: A receita do ambiente pessoal. Declara os pacotes a serem instalados, os aliases do Bash e as configurações de integração do shell.
* flake.lock: Arquivo gerado automaticamente pelo Nix que grava as versões exatas de todas as dependências, garantindo a reprodutibilidade.

---

## Ferramentas e Pacotes Gerenciados

O ambiente está configurado com um ecossistema moderno de ferramentas de terminal voltadas para produtividade e automação:

* Toolkit CLI: bat (substituto do cat), eza (substituto do ls), zoxide (navegação inteligente de diretórios), fzf (busca fuzzy interativa), ripgrep (buscas rápidas em código) e fd (busca otimizada de arquivos).
* Processamento de Dados: jq (JSON) e yq (YAML) para manipulação de manifestos e configurações de CI/CD.
* Orquestração e SCM: lazygit (interface de terminal para Git) e lazydocker (interface de terminal para gerenciamento de contêineres).
* Base do Sistema: git, htop e ferramentas GNU padrão.

---

## Aliases Configurados

O arquivo home.nix injeta aliases focados na otimização de fluxos repetitivos:

* Git Avançado:
  * st: Atalho rápido para status.
  * gfp: Busca atualizações e limpa referências remotas obsoletas (git fetch --prune).
  * glog: Plota a árvore dos últimos 20 commits de forma limpa.
  * gclean-gone e gclean-merged: Scripts automatizados para deleção de branches locais que já foram mescladas ou apagadas no repositório remoto.
* Docker e Laravel:
  * art e pest: Encapsulam a execução do Artisan e do framework Pest diretamente no contêiner da API.
  * dreset: Executa o fluxo completo de recriação de contêineres e scripts de setup local.
  * dtest: Aciona a suíte de testes do pipeline local.

---

## Configuração em uma Nova Máquina

Siga os passos abaixo para replicar exatamente este ambiente em um novo PC com Windows 11 (WSL2) ou Linux nativo.

### Requisitos Prévios

1. WSL2 instalado (se estiver no Windows) com uma distribuição Linux funcional (ex: Ubuntu / Debian).
2. Acesso à Internet para baixar o instalador e os pacotes do cache do Nix.
3. Git instalado na máquina para clonar o repositório.

### Passo a Passo de Instalação

#### 1. Instalar o Nix (Via Determinate Systems)

O instalador da Determinate Systems configura automaticamente os Flakes e gerencia o daemon do Nix de forma limpa no WSL.

```shell
    URL="https://install.determinate.systems/nix"
    curl --proto '=https' --tlsv1.2 -sSf -L "$URL" | sh -s -- install
```

Siga as instruções na tela. Ao finalizar, feche e abra um novo terminal para carregar o ambiente do Nix.

#### 2. Clonar este Repositório

Crie a pasta oculta .dotfiles na sua home e clone o repositório:

```shell
    git clone <URL_DO_SEU_REPOSITORIO_GITHUB> ~/.dotfiles
    cd ~/.dotfiles
```

#### 3. Ajustar o nome do usuário (Se necessário)

Se o nome do usuário do Linux na nova máquina for diferente, lembre-se de atualizar o campo correspondente no arquivo flake.nix e no home.nix.

#### 4. Rodar a Primeira Compilação (Bootstrap)

O Nix lerá o Flake local, baixará as ferramentas necessárias e criará os links simbólicos, fazendo o backup de arquivos conflitantes (como o .bashrc padrão).

```shell
    nix run home-manager/master -- switch --flake .#NOME_DO_USUARIO -b backup
```

#### 5. Recarregar o Shell

Para que as novas ferramentas (como o zoxide) e os aliases entrem em vigor imediatamente:

```shell
    exec bash
```

---

## Fluxo de Trabalho Diário

Sempre que desejar adicionar um novo pacote, criar um alias ou alterar uma configuração:

1. Abra o arquivo `~/.dotfiles/home.nix` e faça as alterações necessárias.
2. Adicione as modificações ao staging area do Git:

    ```shell
        git add home.nix
    ```

3. Aplique a nova configuração:

    ```shell
        home-manager switch --flake ~/.dotfiles/#NOME_DO_USUARIO
    ```

4. Realize o commit (incluindo o flake.lock se houver mudanças de dependências) e envie para o repositório remoto para manter todas as suas máquinas sincronizadas.