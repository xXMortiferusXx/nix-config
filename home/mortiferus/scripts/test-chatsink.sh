#!/run/current-system/sw/bin/bash
# ChatSink Test Script - Generiert einen 5-Sekunden 1kHz Sine-Wave Testton
# und sendet ihn direkt an den ChatSink (HRTF + EQ + Kompressor)

echo "▶️  ChatSink Test: 1kHz Sine-Wave für 5 Sekunden..."
echo "   Lausche im Headset — der Ton sollte frontal präsent sein (HRTF)"
echo "   und durch den Kompressor gleichmäßig laut."
echo ""

# Sendet den Testton an ChatSink via PulseAudio/PipeWire
PULSE_SINK=ChatSink speaker-test -t sine -f 1000 -c 2 -l 1 -d 5

echo ""
echo "✅ Test beendet. Wenn du den Ton gehört hast, funktioniert ChatSink!"
