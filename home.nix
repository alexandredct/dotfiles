{
  config,
  pkgs,
  ...
}: {
  home.username = "alexandre";
  home.homeDirectory = "/home/alexandre";

  home.stateVersion = "23.11";

  # permite o uso de pacotes que tem licenças proprietárias
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # HOME MANAGER
  # ==========================================================================
  programs.home-manager.enable = true;

  # ==========================================================================
  # ZOXIDE (Navegação inteligente de diretórios)
  # ==========================================================================
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  # ==========================================================================
  # STARSHIP (Prompt customizado)
  # ==========================================================================
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  # ==========================================================================
  # DELTA (Diff visual)
  # ==========================================================================
  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      light = false;
    };
  };

  # ==========================================================================
  # GIT (Controle de Versão e Configurações)
  # ==========================================================================
  programs.git = {
    enable = true;

    # ==========================================
    # CONFIGURAÇÃO GLOBAL
    # ==========================================
    settings = {
      user = {
        name = "Alexandre Trindade";
        email = "alexandredct@gmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      fetch.prune = true; # Automatiza a limpeza de metadados remotos obsoletos

      # Força o uso do UTF-8
      i18n = {
        commitEncoding = "utf-8";
        logOutputEncoding = "utf-8";
      };

      core = {
        # Ignora mudanças falsas de permissão de arquivo (essencial para WSL)
        filemode = false;
        # Permite exibir acentos e cedilhas corretamente no git status
        quotepath = false;
      };
    };

    # ==========================================
    # CONFIGURAÇÕES CONDICIONAIS (Trabalho/GitLab)
    # ==========================================
    includes = [
      {
        # O "gitdir:" intercepta qualquer repositório dentro deste caminho
        condition = "gitdir:~/workspace/uerj/";
        contents = {
          user = {
            email = "alexandre.trindade@uerj.br";
          };
        };
      }
    ];
  };

  # ==========================================================================
  # VSCODE
  # ==========================================================================
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # extensões comentadas não estão empacotadas no repo oficial do Nixpkgs, mas existem no VSCode
        bbenoist.nix
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh

        # Docs e outras ferramentas
        #mermaidchart.vscode-mermaid-chart
        #gruntfuggly.todo-tree
        eamodio.gitlens

        # Java
        vscjava.vscode-java-pack
        vscjava.vscode-java-debug
        vscjava.vscode-java-dependency
        vscjava.vscode-maven

        # PHP
        #devsense.phptools-vscode
        xdebug.php-debug
        #laravel.vscode-laravel
        #ryannaddy.laravel-artisan
        #amiralizadeh9480.laravel-extra-intellisense

        # Python
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-python-envs
      ];

      # Configurações do VS Code (settings.json)
      userSettings = {
        "editor.fontFamily" = "'MesloLGS NF', 'Droid Sans Mono', 'monospace'";
        "terminal.integrated.fontFamily" = "'MesloLGS NF'";
        "editor.fontLigatures" = true;
      };
    };
  };

  # ==========================================================================
  # JAVA (LTS)
  # ==========================================================================
  programs.java = {
    enable = true;
    package = pkgs.jdk25;
  };

  # ==========================================================================
  # DIRENV (Carregamento automático de variáveis e ambientes Nix)
  # ==========================================================================
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # ==========================================================================
  # BASH (Shell e Aliases)
  # ==========================================================================
  programs.bash = {
    enable = true;

    # Configurações de histórico do Bash
    historyControl = ["ignoreboth"]; # Ignora comandos duplicados ou que começam com espaço
    historySize = 1000; # Quantidade de comandos mantidos na memória
    historyFileSize = 2000; # Tamanho máximo do arquivo .bash_history

    initExtra = ''
      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Função agy: Abre o Antigravity IDE forçando o modo WSL e resolvendo o caminho absoluto
      agy() {
        local target="''${1:-.}"
        local abs_path="$(realpath "$target")"
        local uri_flag="--folder-uri"
        if [ -f "$abs_path" ] && [[ "$abs_path" == *.code-workspace ]]; then
          uri_flag="--file-uri"
        fi
        "$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" --new-window "$uri_flag" "vscode-remote://wsl+ubuntu-24.04$abs_path"
      }

      # Função agy-history: Consulta, busca e navega pelo histórico de conversas do Antigravity IDE
      # Uso:
      #   agy-history                     -> Lista as conversas mais recentes
      #   agy-history <termo>             -> Busca termo no histórico (ex: workspaces/vscode, tag, depsen)
      #   agy-history -i [termo]          -> Menu interativo (fzf) com pré-visualização das mensagens
      #   agy-history -s <id>             -> Exibe as mensagens detalhadas de uma conversa
      #   agy-history -p <id>             -> Imprime o caminho da pasta da conversa
      #   agy-history -o <id>             -> Abre os arquivos/artefatos da conversa no Antigravity IDE
      agy-history() {
        local script_path="$HOME/.dotfiles/bin/agy-history.py"

        case "$1" in
          -h|--help)
            echo -e "\033[1;34mUso do agy-history:\033[0m"
            echo -e "  agy-history                      -> Lista as conversas mais recentes"
            echo -e "  agy-history <termo>              -> Busca texto (ex: workspaces/vscode, tag, depsen)"
            echo -e "  agy-history -i [termo]           -> Navegador interativo (fzf) com preview das mensagens"
            echo -e "  agy-history -s <id>              -> Mostra histórico detalhado da conversa"
            echo -e "  agy-history -o <id>              -> Abre a pasta da conversa no Antigravity IDE"
            echo -e "  agy-history -p <id>              -> Imprime o caminho da pasta da conversa"
            return 0
            ;;
          -s|--show)
            python3 "$script_path" -s "$2"
            return $?
            ;;
          -p|--path)
            python3 "$script_path" -p "$2"
            return $?
            ;;
          -o|--open)
            local target_dir
            target_dir=$(python3 "$script_path" -p "$2")
            if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
              agy "$target_dir"
            else
              echo -e "\033[1;31mConversa não encontrada: $2\033[0m"
              return 1
            fi
            return 0
            ;;
          -i|--interactive)
            shift
            local query="$*"
            if ! command -v fzf >/dev/null 2>&1; then
              echo "fzf não está instalado. Mostrando modo texto normal:"
              python3 "$script_path" $query
              return $?
            fi

            local selected
            selected=$(python3 "$script_path" --fzf-lines $query | fzf \
              --prompt="Conversa Antigravity > " \
              --height=80% --reverse \
              --preview="python3 '$script_path' -s {2}" \
              --preview-window=right:60%:wrap)

            if [ -n "$selected" ]; then
              local selected_id
              selected_id=$(echo "$selected" | awk -F' \\| ' '{print $2}')
              echo -e "\033[1;32mSelecionado: $selected_id\033[0m"
              read -r -p "Ações: [v] Ver no terminal | [a] Abrir no Antigravity IDE | [c] Cancelar: " act
              case "$act" in
                v|V)
                  python3 "$script_path" -s "$selected_id"
                  ;;
                a|A)
                  agy-history -o "$selected_id"
                  ;;
                *)
                  return 0
                  ;;
              esac
            fi
            return 0
            ;;
          *)
            python3 "$script_path" "$@"
            return $?
            ;;
        esac
      }

      # Função uws: Seleciona ou abre workspaces da UERJ via fzf ou busca direta
      # Uso:
      #   uws            -> Menu interativo fzf (abre no VS Code)
      #   uws assiste    -> Busca e abre o workspace do assiste no VS Code
      #   uws -a assiste -> Abre no Antigravity IDE
      uws() {
        local ws_dir="$HOME/.dotfiles-uerj/workspaces/vscode"
        local is_agy=false
        local query=""

        if [ "$1" = "-a" ] || [ "$1" = "--agy" ]; then
          is_agy=true
          shift
        fi

        query="$1"

        if [ ! -d "$ws_dir" ]; then
          echo "Diretorio de workspaces nao encontrado: $ws_dir"
          return 1
        fi

        _open_ws() {
          local file="$1"
          if [ "$is_agy" = true ]; then
            agy "$file"
          else
            code "$file"
          fi
        }

        if [ -n "$query" ]; then
          local target
          target=$(find "$ws_dir" -maxdepth 1 -name "*$query*.code-workspace" | head -n 1)
          if [ -n "$target" ] && [ -f "$target" ]; then
            _open_ws "$target"
            return 0
          fi
          echo "Workspace contendo '$query' nao encontrado em $ws_dir."
          return 1
        fi

        if command -v fzf >/dev/null 2>&1; then
          local selected
          selected=$(find "$ws_dir" -maxdepth 1 -name "*.code-workspace" -exec basename {} \; | fzf --prompt="Workspace UERJ > " --height=40% --reverse)
          if [ -n "$selected" ]; then
            _open_ws "$ws_dir/$selected"
          fi
        else
          echo "Workspaces disponiveis em $ws_dir:"
          ls -1 "$ws_dir"/*.code-workspace | xargs -n 1 basename | sed 's/\.code-workspace$//'
        fi
      }

      # Função gtag: Automatiza a criação de tags anotadas no padrão DEPSEN (alfa, beta e prod)
      # Suporta:
      #   gtag v1.0.0-alfa.30          -> Cria a tag com confirmação interativa
      #   gtag -d v1.0.0-alfa.30       -> [Dry-Run] Apenas exibe o changelog e qual tag seria criada
      #   gtag --next alfa             -> Calcula automaticamente a próxima tag alfa incremental
      #   gtag -d --next alfa          -> Só mostra qual seria a próxima tag alfa calculada
      gtag() {
        local dry_run=false
        local auto_next=""
        local new_tag=""

        while [ $# -gt 0 ]; do
          case "$1" in
            -d|--dry-run)
              dry_run=true
              shift
              ;;
            -n|--next)
              auto_next="$2"
              shift 2
              ;;
            *)
              new_tag="$1"
              shift
              ;;
          esac
        done

        # Garante que estamos dentro de um repositório git
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          echo -e "\033[1;31mErro:\033[0m Este diretório não é um repositório Git."
          return 1
        fi

        # Cálculo automático da próxima tag se solicitado via --next
        if [ -n "$auto_next" ]; then
          case "$auto_next" in
            alfa)
              local last_alfa
              last_alfa=$(git tag -l "*-alfa.*" --sort=-v:refname | head -n 1)
              if [[ "$last_alfa" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+-alfa\.)([0-9]+)$ ]]; then
                local prefix="''${BASH_REMATCH[1]}"
                local num="''${BASH_REMATCH[2]}"
                new_tag="''${prefix}$((num + 1))"
              else
                echo -e "\033[1;33mNenhuma tag alfa encontrada para incrementar.\033[0m Informe manualmente (ex: gtag v1.0.0-alfa.1)."
                return 1
              fi
              ;;
            beta)
              local last_beta
              last_beta=$(git tag -l "*-beta.*" --sort=-v:refname | head -n 1)
              if [[ "$last_beta" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+-beta\.)([0-9]+)$ ]]; then
                local prefix="''${BASH_REMATCH[1]}"
                local num="''${BASH_REMATCH[2]}"
                new_tag="''${prefix}$((num + 1))"
              else
                # Se não tem beta ainda, extrai da última alfa e inicia com beta.1
                local last_alfa
                last_alfa=$(git tag -l "*-alfa.*" --sort=-v:refname | head -n 1)
                if [[ "$last_alfa" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+)-alfa\.[0-9]+$ ]]; then
                  new_tag="''${BASH_REMATCH[1]}-beta.1"
                else
                  echo -e "\033[1;33mNenhuma tag base encontrada.\033[0m Informe manualmente (ex: gtag v1.0.0-beta.1)."
                  return 1
                fi
              fi
              ;;
            *)
              echo -e "\033[1;31mOpção inválida para --next.\033[0m Use: alfa ou beta."
              return 1
              ;;
          esac
        fi

        if [ -z "$new_tag" ]; then
          echo -e "\033[1;31mErro:\033[0m Informe o nome da tag ou use --next."
          echo -e "Uso:"
          echo -e "  gtag <tag>                 -> Cria a tag com confirmação"
          echo -e "  gtag -d <tag>              -> [Dry-Run] Apenas exibe o que seria feito"
          echo -e "  gtag --next alfa           -> Sugere e cria a próxima tag alfa incremental"
          echo -e "  gtag -d --next alfa        -> Apenas mostra qual seria a próxima tag alfa"
          echo -e "  gtag --next beta           -> Sugere e cria a próxima tag beta incremental"
          return 1
        fi

        local pattern=""
        if [[ "$new_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alfa\.[0-9]+$ ]]; then
          pattern="*-alfa.*"
        elif [[ "$new_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-beta\.[0-9]+$ ]]; then
          pattern="*-beta.*"
        elif [[ "$new_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          pattern="v[0-9]*.[0-9]*.[0-9]*"
        else
          pattern="*"
        fi

        local last_tag
        if [ "$pattern" = "v[0-9]*.[0-9]*.[0-9]*" ]; then
          last_tag=$(git tag -l "v*.*.*" --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
        else
          last_tag=$(git tag -l "$pattern" --sort=-v:refname | head -n 1)
        fi

        # Fallback se for a primeira tag de beta ou prod
        if [ -z "$last_tag" ] && [[ "$new_tag" =~ -beta\. ]]; then
          last_tag=$(git tag -l "*-alfa.*" --sort=-v:refname | head -n 1)
        elif [ -z "$last_tag" ] && [[ "$new_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          last_tag=$(git tag -l "*-beta.*" --sort=-v:refname | head -n 1)
        fi

        local cmd log_output msg
        if [ -n "$last_tag" ]; then
          cmd="git log --oneline $last_tag..HEAD"
          log_output=$(git log --oneline "$last_tag..HEAD")
        else
          cmd="git log --oneline HEAD"
          log_output=$(git log --oneline HEAD)
        fi

        if [ -z "$log_output" ]; then
          echo -e "\033[1;33mAviso:\033[0m Nenhum commit novo desde a tag anterior ($last_tag)."
        fi

        # Monta a mensagem no padrão DEPSEN
        msg=$(printf "%s\n%s" "$cmd" "$log_output")

        echo -e "\033[1;34m========================================\033[0m"
        echo -e "\033[1;34m» Nova Tag:\033[0m      $new_tag"
        echo -e "\033[1;32m» Tag Anterior:\033[0m  ''${last_tag:-Nenhuma (início do repo)}"
        if [ "$dry_run" = true ]; then
          echo -e "\033[1;33m» Modo:\033[0m          DRY-RUN (Simulação - nenhuma tag será criada)"
        fi
        echo -e "\033[1;34m========================================\033[0m"
        echo "$msg"
        echo -e "\033[1;34m========================================\033[0m"

        if [ "$dry_run" = true ]; then
          return 0
        fi

        read -r -p "Confirmar criação da tag? [S/n] " confirm
        confirm="''${confirm:-S}"
        if [[ ! "$confirm" =~ ^[sSyY]$ ]]; then
          echo "Operação cancelada."
          return 0
        fi

        git tag -a "$new_tag" -m "$msg"
        echo -e "\033[1;32m✔ Tag $new_tag criada com sucesso!\033[0m"

        read -r -p "Deseja fazer push da tag para origin? [s/N] " push_confirm
        if [[ "$push_confirm" =~ ^[sSyY]$ ]]; then
          git push origin "$new_tag"
        fi
      }
    '';

    shellAliases = {
      # ======================================================================
      # WORKSPACES UERJ & VSCODE / ANTIGRAVITY
      # ======================================================================
      ws-list = "ls -1 ~/.dotfiles-uerj/workspaces/vscode/*.code-workspace | xargs -n 1 basename | sed 's/\\.code-workspace$//'"; # Lista todos os workspaces disponiveis
      ws-uerj = "cd ~/.dotfiles-uerj/workspaces/vscode"; # Navega para o diretorio de workspaces UERJ

      # ======================================================================
      # NIX & HOME MANAGER
      # ======================================================================
      hms = "home-manager switch --flake ~/.dotfiles#alexandre"; # Aplica as alterações do Nix
      hmn = "home-manager news --flake ~/.dotfiles#alexandre"; # Lẽ as notas de atualização
      hmg = "home-manager generations"; # Lista o histórico de versões
      nfu = "nix flake update --flake ~/.dotfiles"; # Atualiza os canais do Flake
      nix-gc = "nix-collect-garbage -d"; # Faz uma limpeza profunda de espaço em disco no Nix

      # ======================================================================
      # NAVEGAÇÃO E SISTEMA
      # ======================================================================
      ll = "ls -alF"; # Ex: ll
      la = "ls -A"; # Lista arquivos ocultos (exceto . e ..) | Ex: la
      l = "ls -CF"; # Lista em colunas com indicadores de tipo | Ex: l
      st = "git status"; # Ex: st
      grep = "grep --color=auto"; # Destaca resultados da busca com cores
      alert = "notify-send --urgency=low -i \"$([ $? = 0 ] && echo terminal || echo error)\" \"$(history|tail -n1|sed -e '\\''s/^\\s*[0-9]\\+\\s*//;s/[;&|]\\s*alert$//'\\'')\""; # Notificação desktop ao fim de comandos longos (ex: sleep 10; alert)

      # ======================================================================
      # CUSTOMIZAÇÕES E APLICAÇÕES (.bash_aliases)
      # ======================================================================
      depsen = "cd ~/workspace/uerj/git/depsen"; # Atalho para o diretório do projeto depsen
      git-update-all = "for d in */; do (cd \"$d\" && [ -d .git ] && echo -e \"\\n\\033[1;34m» Processando: $d\\033[0m\" && git fetch -p && { git pull --rebase --autostash || { echo -e \"\\033[1;33m⚠ Conflito detectado! Abortando rebase e pulando...\\033[0m\"; git rebase --abort; }; }); done"; # Entra em cada subdiretório e faz um git pull --rebase

      # ======================================================================
      # GIT AVANÇADO E LIMPEZA
      # ======================================================================

      # Sincronização segura: baixa atualizações e já poda referências locais obsoletas
      gfp = "git fetch --prune"; # Ex: gfp

      # Visualização limpa: plota a árvore dos últimos 20 commits com branches
      glog = "git log --oneline --graph -n 20"; # Ex: glog

      # Limpeza Gone: Deleta forçadamente (-D) branches locais que foram apagadas no remoto
      gclean-gone = "git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D";

      # Limpeza Merged: Deleta de forma segura (-d) branches já unidas (exceto main/master)
      gclean-merged = "git branch --merged | grep -v -E '^\\*|main|master' | xargs -r -n 1 git branch -d";

      # ======================================================================
      # DOCKER & LARAVEL
      # ======================================================================
      art = "docker compose exec api php artisan"; # Ex: art migrate:fresh
      pest = "docker compose exec api ./vendor/bin/pest"; # Ex: pest tests/Feature/RouteTest.php

      # Fluxo repetitivo de reset total do ambiente local
      dreset = "docker compose down -v && ./setup.sh && docker compose up -d";

      # Script automatizado de pipeline local
      dtest = "./docker/ci/local_backend_test.sh";
    };
  };

  # ==========================================================================
  # FERRAMENTAS DE TERMINAL (Módulos Nativos)
  # ==========================================================================
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # ==========================================================================
  # PACOTES (Gerenciados pelo Nix)
  # ==========================================================================
  home.packages = with pkgs; [
    # ------------------------------------------------------------------------
    # Core & Diagnósticos
    # ------------------------------------------------------------------------
    hello # Teste GNU                | Ex: hello
    git # Controle de versão       | Ex: git clone <url>
    htop # Monitor de processos     | Ex: htop

    # ------------------------------------------------------------------------
    # Toolkit CLI
    # ------------------------------------------------------------------------
    bat # Substituto do 'cat'      | Ex: bat src/app.env.exemplo
    ripgrep # Busca veloz em arquivos  | Ex: rg "use Spatie"
    fd # Busca veloz de arquivos  | Ex: fd "\.php$"

    # ------------------------------------------------------------------------
    # Processamento de Dados
    # ------------------------------------------------------------------------
    jq # Processador JSON         | Ex: cat file.json | jq '.key'
    yq # Processador YAML         | Ex: yq '.services' docker-compose.yml

    # ------------------------------------------------------------------------
    # SCM
    # ------------------------------------------------------------------------
    lazygit # UI de terminal p/ Git    | Ex: lazygit

    # ------------------------------------------------------------------------
    # Ferramentas Docker
    # ------------------------------------------------------------------------
    docker-compose
    lazydocker # UI para gerenciar contêineres no terminal | Ex: lazydocker

    # ------------------------------------------------------------------------
    # Ferramentas Nix
    # ------------------------------------------------------------------------
    nixd # Language server para Nix (usado pela extensão da IDE)
    alejandra # Formatador de código Nix

    # ------------------------------------------------------------------------
    # Ecossistema Java
    # ------------------------------------------------------------------------
    maven # Gerenciador de dependências e build clássico
    gradle # Sistema de build moderno e flexível
    jdt-language-server # Language server (Autocomplete/IntelliSense para IDE)
    google-java-format # Formatador oficial de código Java

    # ------------------------------------------------------------------------
    # Ecossistema Python
    # ------------------------------------------------------------------------
    (python3.withPackages (ps: with ps; [
      pyyaml
      pip
    ]))
    poetry # Gerenciador de dependências moderno (alternativa melhor ao pip)
    pyright # Language server super rápido da Microsoft para IDE
    ruff # Linter e formatador de código extremamente rápido

    # ------------------------------------------------------------------------
    # Ecossistema PHP
    # ------------------------------------------------------------------------
    php85 # Interpretador nativo PHP 8.5 (caso não queira depender só do Herd Lite)
    php85Packages.composer # Gerenciador de dependências pareado com PHP 8.5
    intelephense # Melhor Language Server para autocomplete PHP/Laravel na IDE

    # ------------------------------------------------------------------------
    # Ferramentas Web / API
    # ------------------------------------------------------------------------
    httpie # Teste de APIs moderno e colorido (substituto amigável do curl)

    # ------------------------------------------------------------------------
    # Ecossistema React / Node.js
    # ------------------------------------------------------------------------
    nodejs # Interpretador base do JavaScript (inclui npm e npx)
    yarn # Gerenciador de pacotes tradicional
    pnpm # Gerenciador de pacotes ultra rápido (muito usado no mundo React moderno)
    typescript-language-server # Inteligência de código para JS/TS e React (JSX/TSX)
    prettier # O formatador oficial do ecossistema front-end
  ];
}
