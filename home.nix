{ config, pkgs, ... }:

{
  home.username = "alexandre";
  home.homeDirectory = "/home/alexandre";

  home.stateVersion = "23.11"; 

  programs.home-manager.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

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
      
      # Atalhos para não precisar digitar o path inteiro do container repetidas vezes
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
    # SCM & Orquestração
    # ------------------------------------------------------------------------
    lazygit    # UI de terminal p/ Git    | Ex: lazygit
    lazydocker # UI de terminal p/ Docker | Ex: lazydocker
  ];
}