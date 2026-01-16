{ pkgs, user, ... }:
{
  imports = [
    ../../../home-manager/default-gaming.nix
    ../../../home-manager/gamescope.nix
  ];

  home.packages = with pkgs; [
    gamescope
    steam
    gamemode
    mangohud
    pavucontrol
  ];

  services.gamescopeSteam = {
    enable = true;
    user = user.name;

    resolution = {
      width = 2560;
      height = 1080;
    };

    refreshRate = 120;

    extraGamescopeArgs = [
      "--adaptive-sync"
      "--hdr-enabled"
    ];
  };

  services.xserver.videoDrivers = [ "nvidia "];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.
}
