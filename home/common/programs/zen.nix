{
  inputs,
  meta,
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
        mkExtensionSettings {
          # Dark Reader
          "addon@darkreader.org" = "darkreader";
          # YouTube
          "sponsorBlocker@ajay.app" = "sponsorblock";
          # Cookies
          "jid1-KKzOGWgsW3Ao4Q@jetpack" = "i-dont-care-about-cookies";
          # Proton
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = "proton-pass";
          "vpn@proton.ch" = "proton-vpn";
          # Refined GitHub
          "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = "refined-github";
          # Wappalyzer
          "wappalyzer@crunchlabz.com" = "wappalyzer";
          # AdBlocker
          "uBlock0@raymondhill.net" = "ublock-origin";
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

      # User Pins
      pins = {
        # Essential Pins - Personal (Always visible across Programming/Universal spaces)
        Google = {
          id = "ae1c1f6e-7cce-49e2-81e2-f5bfae4fbdd8";
          container = containers.Personal.id;
          url = "https://www.google.com/";
          isEssential = true;
          position = 101;
        };
        YouTube = {
          id = "e18e8a47-6d30-496e-ac32-4943086cd3ed";
          container = containers.Personal.id;
          url = "https://www.youtube.com/";
          isEssential = true;
          position = 102;
        };
        GitHub = {
          id = "0cd944c9-8245-4f87-bdbb-9005d512da29";
          container = containers.Personal.id;
          url = "https://github.com/";
          isEssential = true;
          position = 103;
        };
        AppleMusic = {
          id = "d3c40307-d13c-411a-9d61-082d51326454";
          container = containers.Personal.id;
          url = "https://music.apple.com/";
          isEssential = true;
          position = 104;
        };
        Glance = {
          id = "02a4cb5d-c3f2-4a0d-aa1e-987a170144e8";
          container = containers.Personal.id;
          url = "https://glance.home.coredev.uk/";
          isEssential = true;
          position = 105;
        };
        ProtonMail = {
          id = "dda52019-c903-407a-b03a-bf6885131068";
          container = containers.Personal.id;
          url = "https://mail.proton.me/u/0/inbox";
          isEssential = true;
          position = 106;
        };

        # Universal Space Pins
        Outlook = {
          id = "f477aaa9-5e4a-4cdb-8f3c-e960d83f8d01";
          workspace = spaces.Universal.id;
          url = "https://outlook.office.com/mail/";
          position = 201;
        };
        Netflix = {
          id = "4c83bd38-f865-40b1-9179-eaab4d8fc712";
          workspace = spaces.Universal.id;
          url = "https://www.netflix.com/browse";
          position = 202;
        };
        Amazon = {
          id = "e30f7203-747c-4405-874c-326924949782";
          workspace = spaces.Universal.id;
          url = "https://www.amazon.co.uk/";
          position = 203;
        };
        X = {
          id = "d153dec8-e6c4-4b67-a43a-8aeaa04815ad";
          workspace = spaces.Universal.id;
          url = "https://x.com/";
          position = 204;
        };
        Overleaf = {
          id = "e2533eca-3334-4bbf-9055-56985d06d3c1";
          workspace = spaces.Universal.id;
          url = "https://www.overleaf.com/project";
          position = 205;
        };
        Typst = {
          id = "cb6996d4-662d-4299-8c23-c358a7206ab0";
          workspace = spaces.Universal.id;
          url = "https://typst.app/";
          position = 206;
        };

        # Careers Folder (Universal Space)
        Careers = {
          id = "32e52ed2-3472-428d-9e30-aeab8384542b";
          workspace = spaces.Universal.id;
          isFolderCollapsed = false;
          isGroup = true;
          position = 207;
        };
        LinkedIn = {
          id = "2e208ec8-6567-4c04-a321-5a45ac2ae12b";
          workspace = spaces.Universal.id;
          url = "https://www.linkedin.com/feed/";
          folderParentId = pins.Careers.id;
          position = 208;
        };
        BrightNetwork = {
          id = "2a8928f8-d39f-411d-8153-7456f6d59ecc";
          workspace = spaces.Universal.id;
          url = "https://www.brightnetwork.co.uk/dashboard/";
          folderParentId = pins.Careers.id;
          position = 209;
        };
        CVLibrary = {
          id = "ab0c7e6b-d760-4c15-8357-a54f07f22451";
          workspace = spaces.Universal.id;
          url = "https://www.cv-library.co.uk/";
          folderParentId = pins.Careers.id;
          position = 210;
        };
        Gradcracker = {
          id = "03729110-d576-4dc8-8d24-24e7bb1816fb";
          workspace = spaces.Universal.id;
          url = "https://www.gradcracker.com/my-gradcracker";
          folderParentId = pins.Careers.id;
          position = 211;
        };
        TotalJobs = {
          id = "f0dbd77e-9424-406f-9b32-59401b915c86";
          workspace = spaces.Universal.id;
          url = "https://www.totaljobs.com/";
          folderParentId = pins.Careers.id;
          position = 212;
        };

        # Programming Space Pins
        Cloudflare = {
          id = "f740d7ea-f7fb-4c81-9dfc-b1234f07f987";
          workspace = spaces.Programming.id;
          url = "https://dash.cloudflare.com/";
          position = 301;
        };
        "Cloudflare Zero Trust" = {
          id = "fc1c9f49-dc36-4cd0-bf66-6cda3b7c482b";
          workspace = spaces.Programming.id;
          url = "https://one.dash.cloudflare.com/";
          position = 302;
        };
        MyNixOS = {
          id = "10914dc0-6e68-47ae-a888-c1e9b1059c43";
          workspace = spaces.Programming.id;
          url = "https://mynixos.com/";
          position = 303;
        };
        "nvf Configuration" = {
          id = "2a296552-f54f-49c8-aeee-36dcae189b88";
          workspace = spaces.Programming.id;
          url = "https://notashelf.github.io/nvf/options.html";
          position = 304;
        };
        ProtonDB = {
          id = "52743e74-9d79-487a-8d63-84897c58bded";
          workspace = spaces.Programming.id;
          url = "https://www.protondb.com/";
          position = 305;
        };
        AreWeAntiCheatYet = {
          id = "8c43b75c-413b-4616-9554-69ca40e44695";
          workspace = spaces.Programming.id;
          url = "https://areweanticheatyet.com/";
          position = 306;
        };
        "MDN Web Docs" = {
          id = "31be7483-7051-46c8-81b8-0e91f9905ace";
          workspace = spaces.Programming.id;
          url = "https://developer.mozilla.org/";
          position = 307;
        };
        DevDocs = {
          id = "511f9092-542b-46fd-95aa-eb4d0e1e1fbc";
          workspace = spaces.Programming.id;
          url = "https://devdocs.io/";
          position = 308;
        };
        "Can I Use" = {
          id = "1b42522f-de4b-456b-9e48-151b6f64b912";
          workspace = spaces.Programming.id;
          url = "https://caniuse.com/";
          position = 309;
        };
        "Talos Docs" = {
          id = "d814d6e6-0f9d-4980-8237-a71e40fc7999";
          workspace = spaces.Programming.id;
          url = "https://www.talos.dev/";
          position = 310;
        };
        "Kubernetes Docs" = {
          id = "05019cc1-a8de-4182-a3a4-f8176850fbc0";
          workspace = spaces.Programming.id;
          url = "https://kubernetes.io/docs/";
          position = 311;
        };
        RegExr = {
          id = "219610bd-6c24-4d62-a5cc-78c8a666d8af";
          workspace = spaces.Programming.id;
          url = "https://regexr.com/";
          position = 312;
        };
        "JSON Formatter" = {
          id = "94aa339b-8272-4da6-9acf-ae08b474b9b5";
          workspace = spaces.Programming.id;
          url = "https://jsonformatter.org/";
          position = 313;
        };

        # Essential Pins - Work (Always visible in Work space)
        "Google (Work)" = {
          id = "d9730e40-c741-4506-b28c-bc86b928f3e6";
          container = containers.Work.id;
          url = "https://www.google.com/";
          isEssential = true;
          position = 401;
        };
      };
    in
    {
      enable = true;

      languagePacks = [
        "en-GB"
      ];

      policies =
        let
          mkLockedAttrs = builtins.mapAttrs (
            _: value: {
              Value = value;
              Status = "locked";
            }
          );
        in
        {
          # Standard Policies
          AutofillAddressEnabled = true;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          TranslateEnabled = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };

          # Preferences
          Preferences = mkLockedAttrs {
            "browser.tabs.warnOnClose" = false;
            # and so on...
          };

          # Extensions
          ExtensionSettings = extensions;

          profiles.default = {
            name = "Default";
            isDefault = true;

            containersForce = true;
            spacesForce = true;
            pinsForce = true;
            inherit containers spaces pins;
          };
        };
    };
}
