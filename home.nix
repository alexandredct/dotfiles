{ config, pkgs, ... }:

{
  home.username = "alexandre";
  home.homeDirectory = "/home/alexandre";

  home.stateVersion = "23.11"; 

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -alF";
      st = "git status";
    };
  };

  home.packages = with pkgs; [
    hello
    git
    htop
  ];
}
