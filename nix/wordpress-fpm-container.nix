{ pkgs
, unstable
, lib ? pkgs.lib
}:

let
  webport = "8080";
  webroot = "${pkgs.wordpress}/share/wordpress";

  caddyFile = pkgs.writeText "Caddyfile" ''
    :${webport}
    root * ${webroot}
    log
    encode gzip
    php_fastcgi 127.0.0.1:9000
    file_server
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "wordpress-fpm";
  tag = "latest";

  contents = with pkgs; [
    bash
    coreutils
    nushell
    php
    caddy
    fakeNss
    (writeScriptBin "start-server" ''
      #!${runtimeShell}
      php-fpm -D -y /etc/php-fpm.d/www.conf.default
      caddy run --adapter caddyfile --config ${caddyFile}
    '')
  ];

  extraCommands = ''
    mkdir -p tmp
    chmod 1777 tmp
  '';

  config = {
    Cmd = [ "start-server" ];
    ExposedPorts = {
      "${webport}/tcp" = { };
    };
  };
}
