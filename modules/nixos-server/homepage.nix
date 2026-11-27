{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.homepage;

  mkTile =
    {
      name,
      url,
      description,
    }:
    /* html */ ''
      <li>
        <a href="${lib.escapeXML url}">${lib.escapeXML name}</a>
        <p>${lib.escapeXML description}</p>
      </li>
    '';

  mkSection = { name, description, services }: /* html */ ''
    <section>
      <h2>${lib.escapeXML name}</h2>
      <p>${lib.escapeXML description}</p>
      <ul>
        ${lib.concatMapStrings mkTile services}
      </ul>
    </section>
  '';

  indexHTML = pkgs.writeText "index.html" /* html */ ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="Bob homepage">
        <title>Bob</title>
        <link rel="stylesheet" href="style.css">
      </head>

      <body>
        <header>
          <h1>Bob</h1>
          <p>Welcome to Bob, our home server!</p>
        </header>

        <main>
        ${lib.concatMapStrings mkSection cfg.groups}
        </main>
      </body>
    </html>
  '';

  styleCSS = pkgs.writeText "style.css" /* css */ ''
    :root {
      color-scheme: light dark;
    }

    *, *::before, *::after {
      box-sizing: border-box;
    }

    body {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
      min-height: 100dvh;
      max-width: calc(80ch + 2rem);
      margin: 0 auto;
      padding: 1rem;
      font: 1rem/1.6 monospace;
      overflow-wrap: break-word;
      background: light-dark(#ffffff, #151515);
      color: light-dark(#222222, #dddddd);
    }

    main {
      flex-grow: 1;
    }

    a {
      color: light-dark(#0645ad, #8ab4f8);
    }

    li p {
      margin: 0 0 1rem;
    }

    ul {
      list-style-type: square;
    }
  '';

  site = pkgs.runCommandLocal "generate-homepage" { } ''
    set -euf
    mkdir -p $out
    cp ${indexHTML} $out/index.html
    cp ${styleCSS} $out/style.css
  '';
in
{
  options.infra.homepage = {
    enable = lib.mkEnableOption "homepage";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };

    groups = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Group name";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "Group description";
            };

            services = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    name = lib.mkOption {
                      type = lib.types.str;
                      description = "Service name";
                    };

                    url = lib.mkOption {
                      type = lib.types.str;
                      description = "Service URL";
                    };

                    description = lib.mkOption {
                      type = lib.types.str;
                      description = "Service description";
                    };
                  };
                }
              );
              description = "List of services in the group";
            };
          };
        }
      );
      description = "List of groups to be displayed";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;

      virtualHosts.${cfg.hostDomain} = {
        useACMEHost = cfg.hostDomain;
        extraConfig = ''
          ${lib.optionalString config.infra.authelia.enable "import auth *"}
          encode zstd gzip
          root * ${site}
          file_server
        '';
      };
    };
  };
}
