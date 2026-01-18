{ containers, spaces, ... }:
{
  pins = {
    # Essential Pins - Personal (Always visible across Programming/Universal spaces)
    Google = {
      id = "ae1c1f6e-7cce-49e2-81e2-f5bfae4fbdd8";
      container = containers.Personal.id;
      url = "https://www.google.com/";
      isEssential = true;
      position = 0;
    };
    YouTube = {
      id = "e18e8a47-6d30-496e-ac32-4943086cd3ed";
      container = containers.Personal.id;
      url = "https://www.youtube.com/";
      isEssential = true;
      position = 1;
    };
    GitHub = {
      id = "0cd944c9-8245-4f87-bdbb-9005d512da29";
      container = containers.Personal.id;
      url = "https://github.com/";
      isEssential = true;
      position = 2;
    };
    AppleMusic = {
      id = "d3c40307-d13c-411a-9d61-082d51326454";
      container = containers.Personal.id;
      url = "https://music.apple.com/";
      isEssential = true;
      position = 3;
    };
    Glance = {
      id = "02a4cb5d-c3f2-4a0d-aa1e-987a170144e8";
      container = containers.Personal.id;
      url = "https://glance.home.coredev.uk/";
      isEssential = true;
      position = 4;
    };
    ProtonMail = {
      id = "dda52019-c903-407a-b03a-bf6885131068";
      container = containers.Personal.id;
      url = "https://mail.proton.me/u/0/inbox";
      isEssential = true;
      position = 5;
    };

    # Universal Space Pins
    Outlook = {
      id = "f477aaa9-5e4a-4cdb-8f3c-e960d83f8d01";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://outlook.office.com/mail/";
      position = 6;
    };
    Netflix = {
      id = "4c83bd38-f865-40b1-9179-eaab4d8fc712";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.netflix.com/browse";
      position = 7;
    };
    Amazon = {
      id = "e30f7203-747c-4405-874c-326924949782";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.amazon.co.uk/";
      position = 8;
    };
    X = {
      id = "d153dec8-e6c4-4b67-a43a-8aeaa04815ad";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://x.com/";
      position = 9;
    };
    Overleaf = {
      id = "e2533eca-3334-4bbf-9055-56985d06d3c1";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.overleaf.com/project";
      position = 10;
    };
    Typst = {
      id = "cb6996d4-662d-4299-8c23-c358a7206ab0";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://typst.app/";
      position = 11;
    };

    # Careers Folder (Universal Space)
    CareersFolder = {
      id = "32e52ed2-3472-428d-9e30-aeab8384542b";
      title = "Careers";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      isGroup = true;
      position = 13;
    };
    LinkedIn = {
      id = "2e208ec8-6567-4c04-a321-5a45ac2ae12b";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.linkedin.com/feed/";
      folderParentId = "32e52ed2-3472-428d-9e30-aeab8384542b";
      position = 14;
    };
    BrightNetwork = {
      id = "2a8928f8-d39f-411d-8153-7456f6d59ecc";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.brightnetwork.co.uk/dashboard/";
      folderParentId = "32e52ed2-3472-428d-9e30-aeab8384542b";
      position = 15;
    };
    CVLibrary = {
      id = "ab0c7e6b-d760-4c15-8357-a54f07f22451";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.cv-library.co.uk/";
      folderParentId = "32e52ed2-3472-428d-9e30-aeab8384542b";
      position = 16;
    };
    Gradcracker = {
      id = "03729110-d576-4dc8-8d24-24e7bb1816fb";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.gradcracker.com/my-gradcracker";
      folderParentId = "32e52ed2-3472-428d-9e30-aeab8384542b";
      position = 17;
    };
    TotalJobs = {
      id = "f0dbd77e-9424-406f-9b32-59401b915c86";
      container = containers.Personal.id;
      workspace = spaces.Universal.id;
      url = "https://www.totaljobs.com/";
      folderParentId = "32e52ed2-3472-428d-9e30-aeab8384542b";
      position = 18;
    };

    # Programming Space Pins
    Cloudflare = {
      id = "f740d7ea-f7fb-4c81-9dfc-b1234f07f987";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://dash.cloudflare.com/";
      position = 6;
    };
    CloudflareZeroTrust = {
      id = "fc1c9f49-dc36-4cd0-bf66-6cda3b7c482b";
      title = "Cloudflare Zero Trust";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://one.dash.cloudflare.com/";
      position = 7;
    };
    MyNixOS = {
      id = "10914dc0-6e68-47ae-a888-c1e9b1059c43";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://mynixos.com/";
      position = 8;
    };
    NixOSSearch = {
      id = "cd6f68f9-0cbc-436d-8d74-a2348ead90ba";
      title = "NixOS Search";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://search.nixos.org/";
      position = 9;
    };
    NvfDocs = {
      id = "2a296552-f54f-49c8-aeee-36dcae189b88";
      title = "nvf Configuration";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://notashelf.github.io/nvf/options.html";
      position = 10;
    };
    ProtonDB = {
      id = "52743e74-9d79-487a-8d63-84897c58bded";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://www.protondb.com/";
      position = 11;
    };
    AreWeAntiCheatYet = {
      id = "8c43b75c-413b-4616-9554-69ca40e44695";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://areweanticheatyet.com/";
      position = 12;
    };
    MDN = {
      id = "31be7483-7051-46c8-81b8-0e91f9905ace";
      title = "MDN Web Docs";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://developer.mozilla.org/";
      position = 13;
    };
    DevDocs = {
      id = "511f9092-542b-46fd-95aa-eb4d0e1e1fbc";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://devdocs.io/";
      position = 14;
    };
    CanIUse = {
      id = "1b42522f-de4b-456b-9e48-151b6f64b912";
      title = "Can I Use";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://caniuse.com/";
      position = 15;
    };
    TalosLinux = {
      id = "d814d6e6-0f9d-4980-8237-a71e40fc7999";
      title = "Talos Linux";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://www.talos.dev/";
      position = 16;
    };
    KubernetesDocs = {
      id = "05019cc1-a8de-4182-a3a4-f8176850fbc0";
      title = "Kubernetes Docs";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://kubernetes.io/docs/";
      position = 17;
    };
    RegExr = {
      id = "219610bd-6c24-4d62-a5cc-78c8a666d8af";
      title = "RegExr";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://regexr.com/";
      position = 18;
    };
    JSONFormatter = {
      id = "94aa339b-8272-4da6-9acf-ae08b474b9b5";
      title = "JSON Formatter";
      container = containers.Personal.id;
      workspace = spaces.Programming.id;
      url = "https://jsonformatter.org/";
      position = 19;
    };



  };
}
