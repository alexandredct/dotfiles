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
        # Integração com o Delta para diffs coloridos
        pager = "delta";
      };
      
      # Configura o filtro do modo interativo (ex: git add -p) para usar o Delta
      interactive = {
        diffFilter = "delta --color-only";
      };
      
      # Configurações visuais e de atalhos do Delta (tema escuro e navegação habilitada)
      delta = {
        navigate = true;
        light = false;
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
    shellAliases = {
      # ======================================================================
      # NAVEGAÇÃO E SISTEMA
      # ======================================================================
      ll = "ls -alF";                            # Ex: ll
      st = "git status";                         # Ex: st
      
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
    eza     # Substituto do 'ls'       | Ex: eza -la --icons
    fzf     # Buscador interativo      | Ex: history | fzf
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