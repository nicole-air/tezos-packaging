# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{config, lib, pkgs, ...}:

with lib;

let
  tezos-node-pkg = pkgs.tezos.binaries.tezos-node;
  cfg = config.services.tezos-node;
  genConfigCommand = historyMode: rpcPort: netPort: network: ''
                      --data-dir "$node_data_dir" \
                      --history-mode "${cfg.historyMode}" \
                      --rpc-addr ":${toString cfg.rpcPort}" \
                      --net-addr ":${toString cfg.netPort}" \
                      --network "${cfg.network}"
  '';
in {
  options.services.tezos-node = rec {
    enable = mkEnableOption "Tezos node service";

    node-name = mkOption {
      type = types.str;
      default = "edonet";
      description = ''
        Local name of the node, to support running multiple local instances.
      '';
    };

    package = mkOption {
      default = tezos-node-pkg;
      type = types.package;
    };

    rpcPort = mkOption {
      type = types.int;
      default = 8732;
      example = 8732;
      description = ''
        Tezos node RPC port.
      '';
    };

    netPort = mkOption {
      type = types.int;
      default = 9732;
      example = 9732;
      description = ''
        Tezos node net port.
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

    network = mkOption {
      type = types.str;
      default = "edonet";
      description = ''
        Network which node will be running on.
      '';
    };

    historyMode = mkOption {
      type = types.str;
      default = "full";
      description = ''
        Node history mode. Possible values are:
        full, experimental-rolling or arcive.
      '';
    };

    nodeConfig = mkOption {
      default = null;
      type = types.nullOr pkgs.serokell-nix.lib.types.jsonConfig;
      description = ''
        Custom node config.
        This option overrides the all other options that affect
        tezos-node config.
      '';
    };
  };
  config = mkIf cfg.enable {
    users.groups."tezos-${cfg.node-name}" = { };
    users.users."tezos-${cfg.node-name}" = { group = "tezos-${cfg.node-name}"; };
    systemd.services."tezos-${cfg.node-name}-tezos-node" = rec {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Tezos node";
      environment = {
        TEZOS_LOG = "* -> ${cfg.logVerbosity}";
      };
      serviceConfig = {
        User = "tezos-${cfg.node-name}";
        StateDirectory = "tezos-${cfg.node-name}";
        Restart = "always";
        RestartSec = "10";
      };
      preStart =
        if cfg.nodeConfig == null
        then
          ''
            node_dir="$STATE_DIRECTORY/node"
            node_data_dir="$node_dir/data"
            mkdir -p "$node_data_dir"
            # Generate or update node config file
            if [[ ! -f "$node_data_dir/config.json" ]]; then
              ${cfg.package}/bin/tezos-node config init \
              ${genConfigCommand cfg.historyMode cfg.rpcPort cfg.netPort cfg.network}
            else
              ${cfg.package}/bin/tezos-node config update \
              ${genConfigCommand cfg.historyMode cfg.rpcPort cfg.netPort cfg.network}
            fi
          ''
        else
          ''
            node_dir="$STATE_DIRECTORY/node"
            node_data_dir="$node_dir/data"
            mkdir -p "$node_data_dir"
            cp ${cfg.nodeConfig} "$node_data_dir/config.json"
          '';
      script = ''
        ${cfg.package}/bin/tezos-node run --data-dir "$STATE_DIRECTORY/node/data"
      '';
    };
  };
}
