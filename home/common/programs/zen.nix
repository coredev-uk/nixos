{
  inputs,
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
          # 1Password
          "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
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
        Glance = {
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

        # Universal Space Pins
        Outlook = {
          id = "85fa2c24-c107-41a2-aaa4-acb9abf16486";
          workspace = spaces.Universal.id;
          url = "https://outlook.office.com/mail/";
          position = 201;
        };
        Netflix = {
          id = "0a7c203a-c4a8-4cfd-a534-2852cc4a56c7";
          workspace = spaces.Universal.id;
          url = "https://www.netflix.com/browse";
          position = 202;
        };
        Amazon = {
          id = "699e50b2-abb3-403f-a5ec-52b474565f26";
          workspace = spaces.Universal.id;
          url = "https://www.amazon.co.uk/";
          position = 203;
        };
        X = {
          id = "11fde474-8d63-48af-9bc0-338ea3b1f932";
          workspace = spaces.Universal.id;
          url = "https://x.com/";
          position = 204;
        };
        Overleaf = {
          id = "f1648f48-024b-4471-af68-e3bf0b15bf44";
          workspace = spaces.Universal.id;
          url = "https://www.overleaf.com/project";
          position = 205;
        };
        Typst = {
          id = "254a2436-ae49-4ab7-a110-9189f72849d1";
          workspace = spaces.Universal.id;
          url = "https://typst.app/";
          position = 206;
        };

        # Careers Folder (Universal Space)
        Careers = {
          id = "cd4f5481-d0ca-4f31-8ed5-e694302ba7f4";
          workspace = spaces.Universal.id;
          isFolderCollapsed = false;
          isGroup = true;
          editedTitle = true;
          position = 207;
        };
        LinkedIn = {
          id = "de743df8-edff-4b43-b37f-165c19363088";
          workspace = spaces.Universal.id;
          url = "https://www.linkedin.com/feed/";
          folderParentId = pins.Careers.id;
          position = 208;
        };
        BrightNetwork = {
          id = "19a8c304-708f-455b-af36-73bb36b9472c";
          workspace = spaces.Universal.id;
          url = "https://www.brightnetwork.co.uk/dashboard/";
          folderParentId = pins.Careers.id;
          position = 209;
        };
        CVLibrary = {
          id = "88323f4c-b1a8-43f4-af05-f2e12d99ff11";
          workspace = spaces.Universal.id;
          url = "https://www.cv-library.co.uk/";
          folderParentId = pins.Careers.id;
          position = 210;
        };
        Gradcracker = {
          id = "f177c620-c586-4496-bf45-1d72c27a7f08";
          workspace = spaces.Universal.id;
          url = "https://www.gradcracker.com/my-gradcracker";
          folderParentId = pins.Careers.id;
          position = 211;
        };
        TotalJobs = {
          id = "c5a18413-f1a1-4278-a921-f22f9b73eb87";
          workspace = spaces.Universal.id;
          url = "https://www.totaljobs.com/";
          folderParentId = pins.Careers.id;
          position = 212;
        };

        # Programming Space Pins
        Cloudflare = {
          id = "8977af52-68e1-4aa1-9fbf-e4c1be5c0d03";
          workspace = spaces.Programming.id;
          url = "https://dash.cloudflare.com/";
          position = 301;
        };
        "Cloudflare Zero Trust" = {
          id = "ecd206ac-c6bc-4332-8a99-9c3cb716a65a";
          workspace = spaces.Programming.id;
          url = "https://one.dash.cloudflare.com/";
          position = 302;
        };
        MyNixOS = {
          id = "56e19b2c-f0b9-4eb4-8f7c-227fe799b371";
          workspace = spaces.Programming.id;
          url = "https://mynixos.com/";
          position = 303;
        };
        "nvf Configuration" = {
          id = "64234880-c45f-460f-9b9e-c2e627542575";
          workspace = spaces.Programming.id;
          url = "https://notashelf.github.io/nvf/options.html";
          position = 304;
        };
        ProtonDB = {
          id = "baf77b10-5045-4986-8e1e-ef7cb57ee63f";
          workspace = spaces.Programming.id;
          url = "https://www.protondb.com/";
          position = 305;
        };
        AreWeAntiCheatYet = {
          id = "0e13eef7-18ed-41ea-9f1c-82423ec882ff";
          workspace = spaces.Programming.id;
          url = "https://areweanticheatyet.com/";
          position = 306;
        };
        "MDN Web Docs" = {
          id = "b46ad31e-e4f1-4a39-8113-c50bead8f610";
          workspace = spaces.Programming.id;
          url = "https://developer.mozilla.org/";
          position = 307;
        };
        DevDocs = {
          id = "8bac26d4-a81c-439d-bed3-eddea780ae28";
          workspace = spaces.Programming.id;
          url = "https://devdocs.io/";
          position = 308;
        };
        "Can I Use" = {
          id = "f53f18f3-c268-4b8b-b5f2-62724e276d83";
          workspace = spaces.Programming.id;
          url = "https://caniuse.com/";
          position = 309;
        };
        "Talos Docs" = {
          id = "ed075b34-67a5-4547-a390-7b69b7fcabb2";
          workspace = spaces.Programming.id;
          url = "https://www.talos.dev/";
          position = 310;
        };
        "Kubernetes Docs" = {
          id = "620b4234-a4ef-4b74-87fe-6734bffad0a7";
          workspace = spaces.Programming.id;
          url = "https://kubernetes.io/docs/";
          position = 311;
        };
        RegExr = {
          id = "31a2e7ec-16e8-438f-a0d6-22e4b69f5953";
          workspace = spaces.Programming.id;
          url = "https://regexr.com/";
          position = 312;
        };
        "JSON Formatter" = {
          id = "4805f77b-a2dd-4c73-9659-5f1385cd11f2";
          workspace = spaces.Programming.id;
          url = "https://jsonformatter.org/";
          position = 313;
        };

        # Essential Pins - Work (Always visible in Work space)
        "Google (Work)" = {
          id = "79abdada-cc50-4a99-b2cc-c9bf96b4bdb0";
          container = containers.Work.id;
          url = "https://www.google.com/";
          isEssential = true;
          position = 401;
        };
        Loop = {
          id = "b0ad468e-20d2-4f59-86de-def423532d9d";
          container = containers.Work.id;
          url = "https://loop.moto-way.co.uk";
          isEssential = true;
          position = 402;
        };
        Dayforce = {
          id = "503e3c4a-3cc3-4d37-9026-d5f434b265cd";
          container = containers.Work.id;
          url = "https://www.dayforcehcm.com/";
          isEssential = true;
          position = 403;
        };
        MADIC = {
          id = "faedebeb-a00e-4490-8fa8-a9ec41940d68";
          container = containers.Work.id;
          url = "https://moto-evoconnect-portal.madic-uk.com/home";
          isEssential = true;
          position = 404;
        };

        # Work Space Pins
        GSSAT = {
          id = "ecf3d5ff-bd17-427e-bcef-a947c03334f0";
          workspace = spaces.Work.id;
          url = "https://gssat.portofdover.com/";
          position = 501;
        };
        OurMoto = {
          id = "5f9e672c-8c3e-4e55-808e-5e3a597f462c";
          workspace = spaces.Work.id;
          url = "https://our.moto-way.co.uk/";
          position = 502;
        };
        InPost = {
          id = "ee24047b-ddd4-452a-9e94-c08e2112649e";
          workspace = spaces.Work.id;
          url = "https://newstrade.inpost.co.uk/Home/Index";
          position = 503;
        };
        MyView = {
          id = "a9c0fa78-ca8f-4be2-9deb-7ba282ef04b5";
          workspace = spaces.Work.id;
          url = "https://saas.zellis.com/moto/dashboard/dashboard-ui/index.html#/index/main";
          position = 504;
        };
        Tradesimple = {
          id = "8a7e38a2-857a-4181-8f76-bfac230fd01a";
          workspace = spaces.Work.id;
          url = "https://moto.purchase.emea1.fourth.com/";
          position = 505;
        };
        MyAviva = {
          id = "090d1ae2-ecdb-4154-bf13-fd6c42bdad32";
          workspace = spaces.Work.id;
          url = "https://www.direct.aviva.co.uk/MyPortfolio/";
          position = 506;
        };
        AquaVape = {
          id = "59c07cc2-6d2a-4eed-83bd-c3ea7bd9fb35";
          workspace = spaces.Work.id;
          url = "https://wholesale.aquavape.co.uk/";
          position = 507;
        };
        WHSmith = {
          id = "b26c23ad-98f9-4452-a123-1da95a831e2c";
          workspace = spaces.Work.id;
          url = "https://www.wholesale.whsmith.com/";
          position = 508;
        };
        SPAR = {
          id = "948df98d-0321-4f84-b6a0-976ab7a0a72d";
          workspace = spaces.Work.id;
          url = "https://spar.afblakemore.net/pwa/#account-dashboard";
          position = 509;
        };
        MyLearn = {
          id = "d50f2a4a-99ea-416c-abf1-eae007cf8f72";
          workspace = spaces.Work.id;
          url = "https://mylearn.moto-way.co.uk/";
          position = 510;
        };

        # SharePoint Folder (Work Space)
        SharePoint = {
          id = "fcc2411d-a967-44ae-9b11-dea5b86d2f01";
          workspace = spaces.Work.id;
          isFolderCollapsed = false;
          isGroup = true;
          editedTitle = true;
          position = 511;
        };
        "Retail Planograms" = {
          id = "66b78cc9-3bdf-4419-878d-eecb0b6e4c82";
          workspace = spaces.Work.id;
          url = "https://motowaycouk.sharepoint.com/:f:/s/DEPT-Retail-CS/EhUm9PVuBShNjDgoonhezIMB1pEABfEP8Tc3rYTBMT03WQ?e=crQMBT";
          folderParentId = pins.SharePoint.id;
          position = 512;
        };
        "Floor Plans" = {
          id = "3a62c0d4-a838-4f44-bf7f-5a9e0841e0e1";
          workspace = spaces.Work.id;
          url = "https://motowaycouk.sharepoint.com/:f:/s/DEPT-Retail-CS/EoGyKtDOgoRJpwQhViKVDiYBSIXvb9BObXdOqq0hMdiY4g?e=UiRYAd";
          folderParentId = pins.SharePoint.id;
          position = 513;
        };
        "Promo 2026" = {
          id = "a98132e1-78b3-4d12-a5da-e26d230f86eb";
          workspace = spaces.Work.id;
          url = "https://motowaycouk.sharepoint.com/:f:/s/RetailSP/IgBAudmHu8kKRrGi8SjR1v3OAY5ed6-R0nP964ss2lnMdSw?e=Tj3am7";
          folderParentId = pins.SharePoint.id;
          position = 514;
        };
        # Lockheed Folder
        "Lockheed Martin" = {
          id = "9bd93b81-17f1-4a10-9d4b-fbac1d245243";
          workspace = spaces.Work.id;
          isFolderCollapsed = true;
          isGroup = true;
          editedTitle = true;
          position = 515;
        };
        "SAP Work Zone" = {
          id = "70b61d52-a665-43a4-b75f-d8d1eff0815d";
          workspace = spaces.Work.id;
          url = "https://ambkqs9hl.accounts.ondemand.com/saml2/idp/sso?sp=https://lmc-wz4hr-prod-qcdjf9te.authentication.us10.hana.ondemand.com&idp=https://ambkqs9hl.accounts.ondemand.com";
          folderParentId = pins."Lockheed Martin".id;
          position = 516;
        };
      };
    in
    {
      enable = true;

      package = if pkgs.stdenv.isDarwin then null else app;

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
          DisableAppUpdate = !pkgs.stdenv.isDarwin;
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
        };

      profiles.default = {
        name = "Default";
        isDefault = true;

        containersForce = true;
        spacesForce = true;
        pinsForce = true;
        inherit containers spaces pins;
      };
    };
}
