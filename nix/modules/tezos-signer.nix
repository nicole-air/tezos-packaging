# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{config, lib, pkgs, ...}:

with lib;

let
  tezos-signer-launch = "${pkgs.tezos.binaries.tezos-signer}/bin/tezos-signer launch";
  cfg = config.services.tezos-signer;
in {
  options.services.tezos-signer = rec {
    enable = mkEnableOption "Tezos signer service";

    node-name = mkOption {
      type = types.str;
      default = "edonet";
      description = ''
        Local name of the node, to support running multiple local instances.
      '';
    };

    logVerbosity = mkOption {
      type = types.str;
      default = "warning";
      description = ''
        Level of logs verbosity. Possible values are:
        fatal, error, warn, notice, info or debug.
      '';
    };

    networkProtocol = mkOption {
      type = types.str;
      description = ''
        Network protocol version. Supports http, https, tcp and unix.
      '';
      example = "http";
    };

    netAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "127.0.0.1";
      description = ''
        Tezos signer net address.
      '';
    };

    netPort = mkOption {
      type = types.int;
      default = 8080;
      example = 8080;
      description = ''
        Tezos signer net port.
      '';
    };

    certPath = mkOption {
      type = types.str;
      default = null;
      description = ''
        Path of the SSL certificate to use for https Tezos signer.
      '';
    };

    keyPath = mkOption {
      type = types.str;
      default = null;
      description = ''
        Key path to use for https Tezos signer.
      '';
    };

    unixSocket = mkOption {
      type = types.str;
      default = null;
      description = ''
        Socket to use for Tezos signer running over UNIX socket.
      '';
    };

    timeout = mkOption {
      type = types.int;
      default = 1;
      example = 1;
      description = ''
        Timeout for Tezos signer.
      '';
    };

  };
  config = mkIf cfg.enable {
    users.groups."tezos-${cfg.node-name}" = { };
    users.users."tezos-${cfg.node-name}" = { group = "tezos-${cfg.node-name}"; };
    systemd =
      let
        tezos-signers = {
          "http" =
            "${tezos-signer-launch} http signer --address ${cfg.netAddress} --port ${cfg.netPort}";
          "https" =
            "${tezos-signer-launch} https signer ${cfg.certPath} ${cfg.keyPath} --address ${cfg.netAddress} --port ${cfg.netPort}";
          "tcp" =
            "${tezos-signer-launch} socket signer --address ${cfg.netAddress} --port ${cfg.netPort} --timeout ${cfg.timeout}";
          "unix" =
            "${tezos-signer-launch} local signer --socket ${cfg.unixSocket}";
        };
      in {
        services."tezos-${cfg.node-name}-tezos-signer-${cfg.networkProtocol}" = rec {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          description = "Tezos signer";
          environment = {
            TEZOS_LOG = "* -> ${cfg.logVerbosity}";
          };
          serviceConfig = {
            User = "tezos-${cfg.node-name}";
            Group = "tezos-${cfg.node-name}";
            StateDirectory = "tezos-${cfg.node-name}";
            Restart = "always";
            RestartSec = "10";
          };
          script = ''
            ${tezos-signers}.${cfg.networkProtocol}
          '';
        };
      };
  };
}
