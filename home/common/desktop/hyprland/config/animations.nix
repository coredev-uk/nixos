{ luaCall, ... }:
let
  bezier =
    name: x0: y0: x1: y1:
    luaCall [
      name
      {
        type = "bezier";
        points = [
          [
            x0
            y0
          ]
          [
            x1
            y1
          ]
        ];
      }
    ];

  # `speed` is in deciseconds. The compositor is in the way of every keystroke that opens, closes,
  # moves or focuses a window, so it runs quicker than the shell's own tempos (Theme.qml in
  # home/common/programs/quickshell): just long enough to show where a thing went.
  # `switch` is Theme.durationSwitch, which the bar's workspace index shares.
  switch = 1.5;
  focus = 1;
  exit = 0.8;

  anim =
    leaf: speed: curve: style:
    {
      inherit leaf speed;
      enabled = true;
      bezier = curve;
    }
    // (if style == null then { } else { inherit style; });
in
{
  # Meridian moves the way the shell does (Easing.OutCubic in, InCubic out): it arrives and
  # settles, never overshoots. See https://wiki.hypr.land/configuring/core/animations/
  curve = [
    (bezier "settle" 0.33 1 0.68 1)
    (bezier "leave" 0.32 0 0.67 0)
  ];

  animation = [
    (anim "global" switch "settle" null)

    # Windows open a touch below full size and settle; tiling reflows in the same time.
    (anim "windowsIn" switch "settle" "popin 96%")
    (anim "windowsOut" exit "leave" "popin 98%")
    (anim "windowsMove" switch "settle" null)
    (anim "fadeIn" switch "settle" null)
    (anim "fadeOut" exit "leave" null)

    # Focus: the gilt border, the inactive dim and the shadow hand over quickly.
    (anim "border" focus "settle" null)
    (anim "fadeSwitch" focus "settle" null)
    (anim "fadeShadow" focus "settle" null)
    (anim "fadeDim" focus "settle" null)
    {
      leaf = "borderangle";
      enabled = false;
    }

    # Layers (Vicinae, Pass quick access, polkit, the wallpaper picker) and popups (the bar's
    # panels, menus, tooltips) fade in and out as a whole; the shell animates what's inside.
    (anim "layersIn" focus "settle" "fade")
    (anim "layersOut" exit "leave" "fade")
    (anim "fadeLayersIn" focus "settle" null)
    (anim "fadeLayersOut" exit "leave" null)
    (anim "fadePopupsIn" focus "settle" null)
    (anim "fadePopupsOut" exit "leave" null)

    # Workspaces slide a little in the direction of travel as the bar's gilt rule glides to the
    # new numeral, in the same time on the same curve (modules/Workspaces.qml).
    (anim "workspaces" switch "settle" "slidefade 8%")

    (anim "zoomFactor" switch "settle" null)
  ];
}
