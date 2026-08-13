#!/run/current-system/sw/bin/bash
# A/B Test Script fuer Virtual Surround IRs
# Nutzung: ./switch-hrir.sh [atmos|gsx|dts|razer]

IR_DIR="/home/mortiferus/.config/pipewire/hrir_hesuvi"
CONF="/home/mortiferus/.config/pipewire/pipewire.conf.d/chatmixer.conf"

 case "$1" in
    atmos)
        FILE="atmos.wav"
        NAME="Dolby Atmos"
        ;;
    dts-hx)
        FILE="dtshx-.wav"
        NAME="DTS:X Headphone:X"
        ;;
    dts-unbound)
        FILE="DTSSoundUnbound-BalancedOverEar.wav"
        NAME="DTS Sound Unbound (Balanced Over-Ear)"
        ;;
    *)
        echo "Verwendung: $0 [atmos|dts-hx|dts-unbound]"
        echo ""
        echo "Verfuegbare IRs:"
        echo "  atmos        - Dolby Atmos (aktuell)"
        echo "  dts-hx       - DTS:X Headphone:X"
        echo "  dts-unbound  - DTS Sound Unbound (fuer offene Headsets wie Atlas Air)"
        echo ""
        echo "Aktuell: $(grep -o 'hrir_hesuvi/[^\"]*' \"$CONF\" | head -1 | cut -d/ -f2)"
        exit 1
        ;;
esac

if [ ! -f "$IR_DIR/$FILE" ]; then
    echo "FEHLER: $IR_DIR/$FILE nicht gefunden!"
    exit 1
fi

# Alle IR-Referenzen in der Config ersetzen
sed -i "s|hrir_hesuvi/[^\"]*\.wav|hrir_hesuvi/$FILE|g" "$CONF"

echo "🔊 Wechsle zu: $NAME ($FILE)"
echo "   PipeWire wird neu gestartet..."

systemctl --user restart pipewire pipewire-pulse wireplumber
systemctl --user restart noctalia

echo ""
echo "✅ Fertig! Starte dein Spiel neu oder wechsle den Audio-Output kurz."
echo "   Teste 5-10 Minuten, dann entscheide welche IR am besten klingt."
