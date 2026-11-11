{
  inputs,
  lib,
  meta,
  pkgs,
  ...
}:
let
  releaseChannel = "twilight";
  app = inputs.zen-browser.packages.${meta.system}.${releaseChannel};
in
{
  imports = [
    inputs.zen-browser.homeModules.${releaseChannel}
  ];

  xdg.mimeApps.defaultApplicationPackages = [
    app
  ];

  programs.zen-browser =
    let
      # Browser Extensions
      extensions =
        let
          mkExtensionSettings = builtins.mapAttrs (
            _: pluginId: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
              installation_mode = "force_installed";
            }
          );
        in
        {
          # Anything not listed here is blocked, and removed if already installed
          "*".installation_mode = "blocked";
        }
        // mkExtensionSettings {
          # Dark Reader
          "addon@darkreader.org" = "darkreader";
          # YouTube
          "sponsorBlocker@ajay.app" = "sponsorblock";
          # Cookies
          "idcac-pub@guus.ninja" = "istilldontcareaboutcookies";
          # Proton
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = "proton-pass";
          "vpn@proton.ch" = "proton-vpn-firefox-extension";
          # Refined GitHub: off, it made GitHub's pages noticeably slower. Uncomment to try again.
          # "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = "refined-github";
          # Wappalyzer
          "wappalyzer@crunchlabz.com" = "wappalyzer";
          # AdBlocker
          "uBlock0@raymondhill.net" = "ublock-origin";
          # CSFloat Market Cheker
          "{194d0dc6-7ada-41c6-88b8-95d7636fe43c}" = "csgofloat";
          # Firefox Multi-Accounts Containers
          "@testpilot-containers" = "multi-account-containers";
        };

      # Containers
      containers = {
        Personal = {
          color = "blue";
          icon = "fingerprint";
          id = 1;
        };
        Work = {
          color = "orange";
          icon = "briefcase";
          id = 2;
        };
        Banking = {
          color = "green";
          icon = "dollar";
          id = 3;
        };
        Shopping = {
          color = "pink";
          icon = "cart";
          id = 4;
        };
        Facebook = {
          color = "toolbar";
          icon = "fence";
          id = 6;
        };
        TikTok = {
          color = "toolbar";
          icon = "fence";
          id = 7;
        };
      };

      # User Spaces
      spaces = {
        Universal = {
          id = "01ec42f0-1bae-4c03-9ba4-9494b5ccd9f8";
          icon = "🌐";
          container = containers.Personal.id;
          position = 1000;
          pins = {
            Outlook = {
              id = "85fa2c24-c107-41a2-aaa4-acb9abf16486";
              container = containers.Personal.id;
              url = "https://outlook.office.com/mail/";
              position = 201;
            };
            Plex = {
              id = "0a7c203a-c4a8-4cfd-a534-2852cc4a51c7";
              container = containers.Personal.id;
              url = "https://plex.hera.ac";
              position = 202;
            };
            Amazon = {
              id = "699e50b2-abb3-403f-a5ec-52b474565f26";
              container = containers.Personal.id;
              url = "https://www.amazon.co.uk/";
              position = 203;
            };
            X = {
              id = "11fde474-8d63-48af-9bc0-338ea3b1f932";
              container = containers.Personal.id;
              url = "https://x.com/";
              position = 204;
            };
            Outline = {
              id = "f1648f48-024b-4471-af68-e3bf0b15bf44";
              container = containers.Personal.id;
              url = "https://docs.hera.ac";
              position = 205;
            };
            Typst = {
              id = "254a2436-ae49-4ab7-a110-9189f72849d1";
              container = containers.Personal.id;
              url = "https://typst.app/";
              position = 206;
            };
          };
          theme = {
            type = "gradient";
            opacity = 0.5;
            rotation = null;
            texture = 0.0;
            colors = [
              {
                red = 127;
                green = 72;
                blue = 26;
                custom = false;
                algorithm = "analogous";
                lightness = 30;
                position = {
                  x = 237;
                  y = 210;
                };
              }
              {
                red = 77;
                green = 125;
                blue = 28;
                custom = false;
                algorithm = "analogous";
                lightness = 30;
                position = {
                  x = 181;
                  y = 247;
                };
              }
              {
                red = 122;
                green = 31;
                blue = 78;
                custom = false;
                algorithm = "analogous";
                lightness = 30;
                position = {
                  x = 244;
                  y = 143;
                };
              }
            ];
          };
        };
        Programming = {
          id = "cdbae728-7886-4c52-9b38-4d93424a1eaf";
          icon = "💻";
          container = containers.Personal.id;
          position = 2000;
          pins = {
            Cloudflare = {
              id = "8977af52-68e1-4aa1-9fbf-e4c1be5c0d03";
              container = containers.Personal.id;
              url = "https://dash.cloudflare.com/";
              position = 301;
            };
            "Cloudflare Zero Trust" = {
              id = "ecd206ac-c6bc-4332-8a99-9c3cb716a65a";
              container = containers.Personal.id;
              url = "https://dash.cloudflare.com/one/";
              position = 302;
            };
            MyNixOS = {
              id = "56e19b2c-f0b9-4eb4-8f7c-227fe799b371";
              container = containers.Personal.id;
              url = "https://mynixos.com/";
              position = 303;
            };
            "nvf Configuration" = {
              id = "64234880-c45f-460f-9b9e-c2e627542575";
              container = containers.Personal.id;
              url = "https://nvf.notashelf.dev/options.html";
              position = 304;
            };
            ProtonDB = {
              id = "baf77b10-5045-4986-8e1e-ef7cb57ee63f";
              container = containers.Personal.id;
              url = "https://www.protondb.com/";
              position = 305;
            };
            AreWeAntiCheatYet = {
              id = "0e13eef7-18ed-41ea-9f1c-82423ec882ff";
              container = containers.Personal.id;
              url = "https://areweanticheatyet.com/";
              position = 306;
            };
            "MDN Web Docs" = {
              id = "b46ad31e-e4f1-4a39-8113-c50bead8f610";
              container = containers.Personal.id;
              url = "https://developer.mozilla.org/";
              position = 307;
            };
            DevDocs = {
              id = "8bac26d4-a81c-439d-bed3-eddea780ae28";
              container = containers.Personal.id;
              url = "https://devdocs.io/";
              position = 308;
            };
            "Can I Use" = {
              id = "f53f18f3-c268-4b8b-b5f2-62724e276d83";
              container = containers.Personal.id;
              url = "https://caniuse.com/";
              position = 309;
            };
            "Talos Docs" = {
              id = "ed075b34-67a5-4547-a390-7b69b7fcabb2";
              container = containers.Personal.id;
              url = "https://docs.siderolabs.com/talos/";
              position = 310;
            };
            "Kubernetes Docs" = {
              id = "620b4234-a4ef-4b74-87fe-6734bffad0a7";
              container = containers.Personal.id;
              url = "https://kubernetes.io/docs/";
              position = 311;
            };
            RegExr = {
              id = "31a2e7ec-16e8-438f-a0d6-22e4b69f5953";
              container = containers.Personal.id;
              url = "https://regexr.com/";
              position = 312;
            };
            "JSON Formatter" = {
              id = "4805f77b-a2dd-4c73-9659-5f1385cd11f2";
              container = containers.Personal.id;
              url = "https://jsonformatter.org/";
              position = 313;
            };
          };
          theme = {
            type = "gradient";
            opacity = 0.578;
            rotation = null;
            texture = 0.0;
            colors = [
              {
                red = 11;
                green = 68;
                blue = 162;
                custom = false;
                algorithm = "complementary";
                lightness = 16;
                position = {
                  x = 131;
                  y = 143;
                };
              }
              {
                red = 75;
                green = 40;
                blue = 7;
                custom = false;
                algorithm = "complementary";
                lightness = 16;
                position = {
                  x = 207;
                  y = 195;
                };
              }
            ];
          };
        };
        Work = {
          id = "727c9903-928e-4667-9757-6a54c0b445cd";
          icon = "💼";
          container = containers.Work.id;
          position = 3000;
          pins = {
            "Lockheed Martin" = {
              id = "e4fa46bc-cfd5-4c31-8289-4aeda3adf048";
              isFolderCollapsed = true;
              editedTitle = true;
              position = 501;
              pins = {
                MyLM = {
                  id = "c3bd2ad5-aaf6-4258-ac63-0d80fe16cb73";
                  container = containers.Work.id;
                  url = "https://lmc-wz4hr-prod-qcdjf9te.workzonehr.cfapps.us10.hana.ondemand.com/site#workzone-home&/home";
                  position = 502;
                };
                "My Timecard" = {
                  id = "1f0a1ce0-0c29-4cd9-9ed1-345b4cccf515";
                  container = containers.Work.id;
                  url = "https://mytimecard.external.lmco.com/";
                  position = 503;
                };
                TEMPO = {
                  id = "6a72e8fa-20f4-4c7b-a22f-d059d3f2560e";
                  container = containers.Work.id;
                  url = "https://tempo.external.lmco.com/fiori";
                  position = 504;
                };
                "LMTalent Central" = {
                  id = "878bdfdb-db9a-46bb-bdb5-8565532b3cd8";
                  container = containers.Work.id;
                  url = "https://performancemanager8.successfactors.com/login?company=Lockheed";
                  position = 505;
                };
                "Benefits Compass" = {
                  id = "81802c4b-523b-4ccb-9c5b-d2c31510ffad";
                  container = containers.Work.id;
                  url = "https://lmbenefitscompass.com/";
                  position = 506;
                };
                "My Pension Estimator" = {
                  id = "e4b1397f-d565-48a4-8021-5d70f2e4e52f";
                  container = containers.Work.id;
                  url = "https://lmc.lifeatworkportal.com/";
                  position = 507;
                };
                "Annual Reports of Benefit Plans" = {
                  id = "076a9968-8b01-4e71-9673-aabf5c9bde66";
                  container = containers.Work.id;
                  url = "https://www.lockheedmartin.com/en-us/employees/benefit-plans.html";
                  position = 508;
                };
              };
            };
          };
          theme = {
            type = "gradient";
            opacity = 0.635;
            rotation = null;
            texture = 0.5;
            colors = [
              {
                red = 131;
                green = 73;
                blue = 122;
                custom = false;
                algorithm = "analogous";
                lightness = 40;
                position = {
                  x = 265;
                  y = 79;
                };
              }
              {
                red = 138;
                green = 68;
                blue = 66;
                custom = false;
                algorithm = "analogous";
                lightness = 40;
                position = {
                  x = 300;
                  y = 185;
                };
              }
              {
                red = 96;
                green = 80;
                blue = 124;
                custom = false;
                algorithm = "analogous";
                lightness = 40;
                position = {
                  x = 162;
                  y = 38;
                };
              }
            ];
          };
        };
      };

      # Essential pins, shown in every space that uses their container; space pins live in spaces.*.pins
      pins = {
        # Personal (Universal and Programming spaces)
        Google = {
          id = "8e566870-19b6-42d2-81d1-12a2880f313b";
          container = containers.Personal.id;
          url = "https://www.google.com/";
          isEssential = true;
          position = 101;
        };
        YouTube = {
          id = "66bbbc19-aca9-42e9-bf89-e6953006696b";
          container = containers.Personal.id;
          url = "https://www.youtube.com/";
          isEssential = true;
          position = 102;
        };
        GitHub = {
          id = "071b7d28-378a-4db4-ae58-b91af06d85aa";
          container = containers.Personal.id;
          url = "https://github.com/";
          isEssential = true;
          position = 103;
        };
        AppleMusic = {
          id = "6a79ea2e-15c3-41a6-bca4-b1f9f3bb95f8";
          container = containers.Personal.id;
          url = "https://music.apple.com/";
          isEssential = true;
          position = 104;
        };
        Dynacat = {
          id = "a83d151a-eda8-4d53-8e8c-eb01a02b3e40";
          container = containers.Personal.id;
          url = "https://home.hera.ac/";
          isEssential = true;
          position = 105;
        };
        ProtonMail = {
          id = "acc6e781-d6d3-4d23-858a-355553d8ba33";
          container = containers.Personal.id;
          url = "https://mail.proton.me/u/0/inbox";
          isEssential = true;
          position = 106;
        };

        # Work (Work space)
        "Google (Work)" = {
          id = "79abdada-cc50-4a99-b2cc-c9bf96b4bdb0";
          container = containers.Work.id;
          url = "https://www.google.com/";
          isEssential = true;
          position = 401;
        };
      };
    in
    {
      enable = true;

      languagePacks = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [
        "en-GB"
      ];

      policies = {
        # Standard Policies
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        # Proton Pass is the password manager, so the built-in one is off
        PasswordManagerEnabled = false;
        TranslateEnabled = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        # Extensions
        ExtensionSettings = extensions;
      };

      profiles.default = {
        name = "Default";
        isDefault = true;

        settings = {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
        };

        containersForce = true;
        spacesForce = true;
        pinsForce = true;
        inherit containers spaces pins;
      };
    };
}
