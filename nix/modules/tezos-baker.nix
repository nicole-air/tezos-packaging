# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{config, lib, pkgs, ...}:

with lib;

let
  tezos-baker-pkgs = {
    "007-PsDELPH1" =
      "${pkgs.tezos.tezos-baker-007-PsDELPH1}/bin/tezos-baker-007-PsDELPH1";
    "008-PtEdo2Zk" =
      "${pkgs.tezos.tezos-baker-008-PtEdo2Zk}/bin/tezos-baker-008-PtEdo2Zk";
  };
  cfg = config.services.tezos-baker;
in {
  options.services.tezos-baker = rec {
    enable = mkEnableOption "Tezos baker service";

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

    baseProtocol = mkOption {
      type = types.str;
      description = ''
        Base protocol version,
        only '007-PsDELPH1' and '008-PtEdo2Zk' are supported.
      '';
      example = "008-PtEdo2Zk";
    };

  };
  config = mkIf cfg.enable {
    users.groups."tezos-${cfg.node-name}" = { };
    users.users."tezos-${cfg.node-name}" = { group = "tezos-${cfg.node-name}"; };
    systemd.services."tezos-${cfg.node-name}-tezos-baker" = rec {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Tezos baker";
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
        ${tezos-baker-pkgs}.${cfg.baseProtocol}
      '';
    };
  };
}
