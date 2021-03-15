# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{config, lib, pkgs, ...}:

with lib;

let
  tezos-endorser-pkgs = {
    "007-PsDELPH1" =
      "${pkgs.tezos.tezos-endorser-007-PsDELPH1}/bin/tezos-endorser-007-PsDELPH1";
    "008-PtEdo2Zk" =
      "${pkgs.tezos.tezos-endorser-008-PtEdo2Zk}/bin/tezos-endorser-008-PtEdo2Zk";
  };
  cfg = config.services.tezos-endorser;
in {
  options.services.tezos-endorser = rec {
    enable = mkEnableOption "Tezos endorser service";

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
    systemd.services."tezos-${cfg.node-name}-tezos-endorser" = rec {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Tezos endorser";
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
        ${tezos-endorser-pkgs}.${cfg.baseProtocol}
      '';
    };
  };
}
