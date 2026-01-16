{ lib, pkgs, config, ... }:

let
  cfg = config.services.gamescopeSteam;

  sessionScript = pkgs.writeShellScript "gamescope-steam-session" ''
    set -euo pipefail

    # Wayland session identity
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=gamescope
    export XDG_SESSION_DESKTOP=gamescope

    # NVIDIA + Gamescope compatibility
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export GBM_BACKEND=nvidia-drm
    export WLR_NO_HARDWARE_CURSORS=1

    # SDL / audio / general desktop sanity
    export SDL_VIDEODRIVER=wayland
    export SDL_AUDIODRIVER=pipewire
    export QT_QPA_PLATFORM=wayland
    export MOZ_ENABLE_WAYLAND=1

    # Optional latency / performance niceties
    export __GL_SYNC_TO_VBLANK=0
    export __GL_MaxFramesAllowed=1

    exec ${pkgs.gamescope}/bin/gamescope \
      -e \
      ${lib.optionalString (cfg.resolution != null)
        "-W ${toString cfg.resolution.width} -H ${toString cfg.resolution.height}"} \
      ${lib.optionalString (cfg.refreshRate != null)
        "-r ${toString cfg.refreshRate}"} \
      ${lib.concatStringsSep " " cfg.extraGamescopeArgs} \
      -- \
      ${cfg.steamPackage}/bin/steam -tenfoot ${lib.concatStringsSep " " cfg.extraSteamArgs}
  '';
in
{
  options.services.gamescopeSteam = {
    enable = lib.mkEnableOption "Boot directly into Gamescope + Steam Big Picture (Wayland)";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Existing user account used to run the Gamescope session.";
    };

    steamPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.steam;
      description = "Steam package to launch.";
    };

    resolution = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          width  = lib.mkOption { type = lib.types.int; };
          height = lib.mkOption { type = lib.types.int; };
        };
      });
      default = null;
      description = "Optional forced output resolution.";
    };

    refreshRate = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Optional forced refresh rate (Hz).";
    };

    extraGamescopeArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments passed to Gamescope.";
      example = [ "--adaptive-sync" "--hdr-enabled" ];
    };

    extraSteamArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments passed to Steam.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Minimal login manager: no desktop, no greeter UI
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = cfg.user;
        command = sessionScript;
      };
    };
  };
}
