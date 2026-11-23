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

  # `speed` is in deciseconds; quicker than the shell's tempos (Theme.qml in programs/quickshell).
  # `switch` is Theme.durationSwitch, shared with the bar's workspace index.
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
  # Matches the shell's easing (OutCubic in, InCubic out): settles, never overshoots.
  # https://wiki.hypr.land/configuring/core/animations/
  curve = [
    (bezier "settle" 0.33 1 0.68 1)
    (bezier "leave" 0.32 0 0.67 0)
  ];

  animation = [
    (anim "global" switch "settle" null)

    # Windows open slightly below full size and settle.
    (anim "windowsIn" switch "settle" "popin 96%")
    (anim "windowsOut" exit "leave" "popin 98%")
    (anim "windowsMove" switch "settle" null)
    (anim "fadeIn" switch "settle" null)
    (anim "fadeOut" exit "leave" null)

    # Focus: border, inactive dim and shadow.
    (anim "border" focus "settle" null)
    (anim "fadeSwitch" focus "settle" null)
    (anim "fadeShadow" focus "settle" null)
    (anim "fadeDim" focus "settle" null)
    {
      leaf = "borderangle";
      enabled = false;
    }

    # Layers and popups fade as a whole; the shell animates their contents.
    (anim "layersIn" focus "settle" "fade")
    (anim "layersOut" exit "leave" "fade")
    (anim "fadeLayersIn" focus "settle" null)
    (anim "fadeLayersOut" exit "leave" null)
    (anim "fadePopupsIn" focus "settle" null)
    (anim "fadePopupsOut" exit "leave" null)

    # Slides with the bar's workspace rule, same time and curve (modules/Workspaces.qml).
    (anim "workspaces" switch "settle" "slidefade 8%")

    (anim "zoomFactor" switch "settle" null)
  ];
}
