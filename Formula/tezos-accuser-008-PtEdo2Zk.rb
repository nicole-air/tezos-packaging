# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

class TezosAccuser008Ptedo2zk < Formula
  @all_bins = []

  class << self
    attr_accessor :all_bins
  end
  homepage "https://gitlab.com/tezos/tezos"

  url "https://gitlab.com/tezos/tezos.git", :tag => "v8.2", :shallow => false

  version "v8.2-3"

  build_dependencies = %w[pkg-config autoconf rsync wget opam rustup-init]
  build_dependencies.each do |dependency|
    depends_on dependency => :build
  end

  dependencies = %w[gmp hidapi libev libffi]
  dependencies.each do |dependency|
    depends_on dependency
  end
  desc "Daemon for accusing"

  bottle do
    root_url "https://github.com/serokell/tezos-packaging/releases/download/#{TezosAccuser008Ptedo2zk.version}/"
    cellar :any
    sha256 "4efaedef768f5114ae6e142aeba62c883e1703bcaf725a9c53cceee0f55c4427" => :mojave
    sha256 "12378615cf0f6291e89f58e8c6aa04aef56d52d823dcab18bb72d954fb7e4b73" => :catalina
  end

  def make_deps
    ENV.deparallelize
    ENV["CARGO_HOME"]="./.cargo"
    system "rustup-init", "--default-toolchain", "1.44.0", "-y"
    system "opam", "init", "--bare", "--debug", "--auto-setup", "--disable-sandboxing"
    system ["source .cargo/env",  "make build-deps"].join(" && ")
  end

  def install_template(dune_path, exec_path, name)
    bin.mkpath
    self.class.all_bins << name
    system ["eval $(opam env)", "dune build #{dune_path}", "cp #{exec_path} #{name}"].join(" && ")
    bin.install name
  end

  def install
    startup_contents =
      <<~EOS
      #!/usr/bin/env bash

      set -euo pipefail

      accuser="#{bin}/tezos-accuser-008-PtEdo2Zk"

      accuser_dir="$DATA_DIR"

      accuser_config="$accuser_dir/config"
      mkdir -p "$accuser_dir"

      if [ ! -f "$accuser_config" ]; then
          "$accuser" --base-dir "$accuser_dir" \
                    --endpoint "$NODE_RPC_ENDPOINT" \
                    config init --output "$accuser_config" >/dev/null 2>&1
      else
          "$accuser" --base-dir "$accuser_dir" \
                    --endpoint "$NODE_RPC_ENDPOINT" \
                    config update >/dev/null 2>&1
      fi

      exec "$accuser" --base-dir "$accuser_dir" \
          --endpoint "$NODE_RPC_ENDPOINT" \
          run
    EOS
    File.write("tezos-accuser-008-PtEdo2Zk-start", startup_contents)
    bin.install "tezos-accuser-008-PtEdo2Zk-start"
    make_deps
    install_template "src/proto_008_PtEdo2Zk/bin_accuser/main_accuser_008_PtEdo2Zk.exe",
                     "_build/default/src/proto_008_PtEdo2Zk/bin_accuser/main_accuser_008_PtEdo2Zk.exe",
                     "tezos-accuser-008-PtEdo2Zk"
  end

  plist_options manual: "tezos-accuser-008-PtEdo2Zk run"
  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>Program</key>
          <string>#{opt_bin}/tezos-accuser-008-PtEdo2Zk-start</string>
          <key>EnvironmentVariables</key>
            <dict>
              <key>DATA_DIR</key>
              <string>#{var}/lib/tezos/client</string>
              <key>NODE_RPC_ENDPOINT</key>
              <string>http://localhost:8732</string>
          </dict>
          <key>RunAtLoad</key><true/>
          <key>StandardOutPath</key>
          <string>#{var}/log/#{name}.log</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/#{name}.log</string>
        </dict>
      </plist>
    EOS
  end
  def post_install
    mkdir "#{var}/lib/tezos/client"
  end
end
