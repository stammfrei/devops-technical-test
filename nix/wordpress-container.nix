{ pkgs
, unstable
, lib ? pkgs.lib
}:

#with pkgs.lib;

let
  user = "www-data";
  uid = 33;
  # Module https://httpd.apache.org/docs/2.4/mod/
  # 
  apacheConfigFile = pkgs.writeText "httpd.conf" ''
    LoadModule mpm_event_module ${pkgs.apacheHttpd}/modules/mod_mpm_event.so
    LoadModule log_config_module ${pkgs.apacheHttpd}/modules/mod_log_config.so
    LoadModule logio_module ${pkgs.apacheHttpd}/modules/mod_logio.so
    LoadModule authz_user_module ${pkgs.apacheHttpd}/modules/mod_authz_user.so
    LoadModule authn_file_module ${pkgs.apacheHttpd}/modules/mod_authn_file.so
    LoadModule authn_core_module ${pkgs.apacheHttpd}/modules/mod_authn_core.so
    LoadModule authz_core_module ${pkgs.apacheHttpd}/modules/mod_authz_core.so
    LoadModule authz_host_module ${pkgs.apacheHttpd}/modules/mod_authz_host.so
    LoadModule authz_groupfile_module ${pkgs.apacheHttpd}/modules/mod_authz_groupfile.so
    LoadModule authz_user_module ${pkgs.apacheHttpd}/modules/mod_authz_user.so
    LoadModule mime_module ${pkgs.apacheHttpd}/modules/mod_mime.so
    LoadModule unixd_module ${pkgs.apacheHttpd}/modules/mod_unixd.so
    LoadModule dir_module ${pkgs.apacheHttpd}/modules/mod_dir.so
    LoadModule php_module /path/to/mods-available/libphpX.so


    <IfModule mpm_event_module>
            StartServers                     2
            MinSpareThreads          25
            MaxSpareThreads          75
            ThreadLimit                      64
            ThreadsPerChild          25
            MaxRequestWorkers         150
            MaxConnectionsPerChild   0
    </IfModule>
    <IfModule log_config_module>
        #
        # The following directives define some format nicknames for use with
        # a CustomLog directive (see below).
        #
        LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
        LogFormat "%h %l %u %t \"%r\" %>s %b" common

        <IfModule logio_module>
          # You need to enable mod_logio.c to use %I and %O
          LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
        </IfModule>

        CustomLog "/dev/stderr" combined
    </IfModule>

    ${lib.readFile ./src/apache2.conf}
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-wordpress";
  tag = "latest";

  config = {
    Cmd = [
      "${pkgs.apacheHttpd}/bin/apachectl"
      "-f"
      "${apacheConfigFile}"
      "-D"
      "FOREGROUND"
    ];
  };

  created = "now";

  # copyToRoot = pkgs.buildEnv {
  #   name = "image-root";
  #   paths = [
  #     pkgs.binSh
  #     pkgs.fakeNss
  #   ];
  #   pathsToLink = [
  #     "/bin"
  #     "/etc"
  #     "/var"
  #   ];
  # };

  contents =
    let
      makeNonRootUser = { user, uid, gid ? uid }: with pkgs; [
        (
          writeTextDir "etc/shadow" ''
            root:!x:::::::
            ${user}:!:::::::
          ''
        )
        (
          writeTextDir "etc/passwd" ''
            root:x:0:0::/root:
            ${user}:x:${toString uid}:${toString gid}::/home/${user}:
          ''
        )
        (
          writeTextDir "etc/group" ''
            root:x:0:
            ${user}:x:${toString gid}:
          ''
        )
        (
          writeTextDir "etc/gshadow" ''
            root:x::
            ${user}:x::
          ''
        )
      ];
    in
    with pkgs; [
      apacheHttpd
      apacheHttpdPackages.php
      cacert

      # debug
      su
      bash
      coreutils
      nushell

      # php
      (php82.withExtensions ({ all, ... }: with all; [ imagick opcache mysqli ]))

      dockerTools.caCertificates
      dockerTools.usrBinEnv
      dockerTools.binSh
    ]
    ++ (makeNonRootUser { inherit user uid; })
  ;

  enableFakechroot = true;
  fakeRootCommands = ''
    echo "Create the apache2 directory" 
    mkdir -p /var/lib/httpd/run
    chown -R 33:33 /var/lib
  '';
}
