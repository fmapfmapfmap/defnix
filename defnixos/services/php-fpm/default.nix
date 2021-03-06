defnix: let
  inherit (defnix.defnixos.activations) socket;

  inherit (defnix.pkgs) multiplex-activations execve php;
in

{ socket-path # The path to the fpm socket
, config # the php-fpm config file
, ini ? "${php}/etc/php-recommended.ini" # php.ini
}:

{
  start = multiplex-activations [ (socket {
    family = defnix.lib.socket-address-families.AF_UNIX;

    path = socket-path;
  }) ] (execve "start-php-fpm" {
    filename = "${php}/sbin/php-fpm";

    argv = [ "php-fpm" "--fpm-config" config "-c" ini ];

    envp = {
      FPM_SOCKETS = "${socket-path}=3";
    };
  });

  on-demand = true;
}
