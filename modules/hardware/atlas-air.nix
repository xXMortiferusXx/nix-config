# Turtle Beach Atlas Air Kopfhörer – stabiler Node-Name via PipeWire/WirePlumber
# Verhindert dass ALSA den Namen bei jedem Reconnect ändert + deaktiviert USB Autosuspend
{ ... }:

{
  # USB Autosuspend deaktivieren – sonst schaltet sich das Headset bei Mikro-Stumme ab
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="10f5", ATTRS{idProduct}=="225e", ATTR{power/control}="on"
  '';

  services.pipewire.wireplumber.extraConfig."10-atlas-air" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "node.name" = "~alsa_output.usb-Turtle_Beach_Corp_Atlas_Air.*";
          }
        ];
        actions = {
          update-props = {
            "node.name" = "alsa_output.atlas_air_headset";
            "node.description" = "Atlas Air Headset (Stabil)";
          };
        };
      }
    ];
  };
}
