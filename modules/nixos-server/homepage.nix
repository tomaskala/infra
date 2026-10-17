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
        <a class="tile" href="${lib.escapeXML url}">
          <span class="name">${lib.escapeXML name}</span>
          <span class="description">${lib.escapeXML description}</span>
        </a>
      </li>
    '';

  mkGroup = { name, services }: /* html */ ''
    <section>
      <h2>${lib.escapeXML name}</h2>
      <ul class="grid">
        ${lib.concatMapStrings mkTile services}
      </ul>
    </section>
  '';

  indexHTML = pkgs.writeText "index.html" /* html */ ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <meta name="color-scheme" content="light dark">
        <meta name="description" content="Bob homepage">
        <title>Bob</title>
        <link rel="stylesheet" href="style.css">
      </head>

      <body>
        <header>
          <h1>Bob</h1>
        </header>

        <main>
        <nav aria-label="Services">
            ${lib.concatMapStrings mkGroup cfg.groups}
        </nav>
        </main>
      </body>
    </html>
  '';

  styleCSS = pkgs.writeText "style.css" /* css */ ''
    :root {
      color-scheme: light dark;
      --bg: #f4f5f9;
      --surface: #ffffff;
      --text: #1b1d26;
      --muted: #586174;
      --border: #d9dde8;
      --accent: #4a5bf0;
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0f1117;
        --surface: #181b24;
        --text: #e8eaf2;
        --muted: #9aa2b6;
        --border: #2b3040;
        --accent: #8f9bff;
      }
    }

    * { box-sizing: border-box; }

    body {
      max-width: 64rem;
      margin: 0 auto;
      padding:
        max(clamp(1.5rem, 5vw, 3rem), env(safe-area-inset-top))
        max(1rem, env(safe-area-inset-right))
        max(2rem, env(safe-area-inset-bottom))
        max(1rem, env(safe-area-inset-left));
      background: var(--bg);
      color: var(--text);
      font: 1rem/1.4 system-ui, sans-serif;
    }

    h1 {
      margin: 0 0 2rem;
      font-size: clamp(1.75rem, 5vw, 2.5rem);
      line-height: 1.1;
      letter-spacing: -0.02em;
    }

    section + section { margin-top: 2rem; }

    h2 {
      margin: 0 0 0.75rem 0.25rem;
      font-size: 0.8rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--muted);
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(min(100%, 15rem), 1fr));
      gap: 0.75rem;
      margin: 0;
      padding: 0;
      list-style: none;
    }

    .tile {
      display: flex;
      flex-direction: column;
      height: 100%;
      padding: 0.9rem 1.1rem;
      color: inherit;
      text-decoration: none;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      transition: border-color 0.15s;
    }

    .tile:hover { border-color: var(--accent); }

    .tile:focus-visible {
      outline: 2px solid var(--accent);
      outline-offset: 2px;
    }

    .name { font-weight: 600; }
    .description { color: var(--muted); font-size: 0.85rem; }
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
