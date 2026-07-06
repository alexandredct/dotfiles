{ config, pkgs, ... }:

{
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
  # BASH (Shell e Aliases)
  # ==========================================================================
  programs.bash = {
    enable = true;

    # Configurações de histórico do Bash
    historyControl = [ "ignoreboth" ];         # Ignora comandos duplicados ou que começam com espaço
    historySize = 1000;                        # Quantidade de comandos mantidos na memória
    historyFileSize = 2000;                    # Tamanho máximo do arquivo .bash_history

    initExtra = ''
      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Herd Lite PHP
      export PATH="/home/alexandre/.config/herd-lite/bin:$PATH"
      export PHP_INI_SCAN_DIR="/home/alexandre/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
    '';

    shellAliases = {
      # ======================================================================
      # NAVEGAÇÃO E SISTEMA
      # ======================================================================
      ll = "ls -alF";                            # Ex: ll
      la = "ls -A";                              # Lista arquivos ocultos (exceto . e ..) | Ex: la
      l = "ls -CF";                              # Lista em colunas com indicadores de tipo | Ex: l
      st = "git status";                         # Ex: st
      grep = "grep --color=auto";                # Destaca resultados da busca com cores
      alert = "notify-send --urgency=low -i \"$([ $? = 0 ] && echo terminal || echo error)\" \"$(history|tail -n1|sed -e '\\''s/^\\s*[0-9]\\+\\s*//;s/[;&|]\\s*alert$//'\\'')\""; # Notificação desktop ao fim de comandos longos (ex: sleep 10; alert)
      
      # ======================================================================
      # CUSTOMIZAÇÕES E APLICAÇÕES (.bash_aliases)
      # ======================================================================
      agy = ''"$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"/AppData/Local/Programs/Antigravity/bin/antigravity &> /dev/null &''; # Abre o IDE do Google Antigravity em segundo plano
      depsen = "cd ~/workspace/uerj/git/depsen"; # Atalho para o diretório do projeto depsen
      git-update-all = "for d in */; do (cd \"$d\" && [ -d .git ] && echo -e \"\\n\\033[1;34m» Processando: $d\\033[0m\" && git fetch -p && { git pull --rebase --autostash || { echo -e \"\\033[1;33m⚠ Conflito detectado! Abortando rebase e pulando...\\033[0m\"; git rebase --abort; }; }); done"; # Entra em cada subdiretório e faz um git pull --rebase
      
      # ======================================================================
      # GIT AVANÇADO E LIMPEZA
      # ======================================================================
      
      # Sincronização segura: baixa atualizações e já poda referências locais obsoletas
      gfp = "git fetch --prune";                 # Ex: gfp
      
      # Visualização limpa: plota a árvore dos últimos 20 commits com branches
      glog = "git log --oneline --graph -n 20";  # Ex: glog
      
      # Limpeza Gone: Deleta forçadamente (-D) branches locais que foram apagadas no remoto
      gclean-gone = "git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D"; 
      
      # Limpeza Merged: Deleta de forma segura (-d) branches já unidas (exceto main/master)
      gclean-merged = "git branch --merged | grep -v -E '^\\*|main|master' | xargs -r -n 1 git branch -d";
      
      # ======================================================================
      # DOCKER & LARAVEL
      # ======================================================================
      art = "docker compose exec api php artisan";        # Ex: art migrate:fresh
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
    hello   # Teste GNU                | Ex: hello
    git     # Controle de versão       | Ex: git clone <url>
    htop    # Monitor de processos     | Ex: htop

    # ------------------------------------------------------------------------
    # Toolkit CLI
    # ------------------------------------------------------------------------
    bat     # Substituto do 'cat'      | Ex: bat src/app.env.exemplo
    ripgrep # Busca veloz em arquivos  | Ex: rg "use Spatie"
    fd      # Busca veloz de arquivos  | Ex: fd "\.php$"
    
    # ------------------------------------------------------------------------
    # Processamento de Dados
    # ------------------------------------------------------------------------
    jq      # Processador JSON         | Ex: cat file.json | jq '.key'
    yq      # Processador YAML         | Ex: yq '.services' docker-compose.yml
    
    # ------------------------------------------------------------------------
    # SCM
    # ------------------------------------------------------------------------
    lazygit    # UI de terminal p/ Git    | Ex: lazygit
    
    # ------------------------------------------------------------------------
    # Ferramentas Docker
    # ------------------------------------------------------------------------
    docker-compose
    lazydocker # UI para gerenciar contêineres no terminal | Ex: lazydocker
  ];
}