# Touchpad bei angeschlossener USB-Maus automatisch deaktivieren
# udev-getriggertes Script inhibiert das Touchpad-Device via /sys/class/input
{ pkgs, lib, ... }:

let
  toggleScript = pkgs.writeShellScript "touchpad-toggle" ''
    # Touchpad-Device dynamisch über Namen finden
    TOUCHPAD_INHIBIT=""
    for dev in /sys/class/input/event*/; do
      devname=$(cat "$dev/device/name" 2>/dev/null || true)
      # Nur echtes Touchpad, nicht den ELAN-Mouse-Node
      if echo "$devname" | grep -qi "touchpad\|trackpad"; then
        TOUCHPAD_INHIBIT="$dev/device/inhibited"
        break
      fi
    done

    if [ -z "$TOUCHPAD_INHIBIT" ]; then
      exit 0  # Kein Touchpad gefunden
    fi

    # Externe Mäuse zählen – interne ELAN/Synaptics-Devices ausschließen
    EXT_MOUSE=0
    for mouse in /sys/class/input/mouse*/; do
      devname=$(cat "$mouse/device/name" 2>/dev/null || true)
      if ! echo "$devname" | grep -qi "ELAN\|touchpad\|trackpad\|synaptics"; then
        EXT_MOUSE=$((EXT_MOUSE + 1))
      fi
    done

    if [ "$EXT_MOUSE" -gt 0 ]; then
      echo 1 > "$TOUCHPAD_INHIBIT"
    else
      echo 0 > "$TOUCHPAD_INHIBIT"
    fi
  '';
in
{
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="input", KERNEL=="mouse[0-9]*", ACTION=="add",    RUN+="${toggleScript}"
    SUBSYSTEM=="input", KERNEL=="mouse[0-9]*", ACTION=="remove", RUN+="${toggleScript}"
  '';
}
