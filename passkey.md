# Passkey – Planung (FIDO2 / YubiKey)

Zweck: Festhalten, was wir für die Passkey-Umrüstung auf **nex (mortiferus)** brauchen,
damit wir nach dem Kauf des Keys direkt loslegen können. **Status: geplant, noch nicht
umgesetzt** — Key ist noch nicht bestellt.

Referenz: `memory.md` (Grundlagen), `lion-pc.md`/`umbriel.md` (Format).

---

## Ziel & Scope
- **Nur nex (mortiferus)** — lion-pc/styx bleiben unangetastet.
  - lion ist 10: Passkey-Risiko (Verlust/Defekt) zu hoch, noch unnötig.
- Alles, was Passwort kann, nach und nach auf Passkey/FIDO2 umstellen.

## Key-Empfehlung
- **YubiKey 5C NFC** (~55–65 € auf Amazon.de) — USB-C + NFC, 100 Passkey-Slots,
  Firmware 5.8, FIDO2 CTAP2.1 + U2F, PIV/OpenPGP/OATH-TOTP.
- Alternativen (Budget): Yubico Security Key C NFC (~30 €, nur FIDO2/U2F),
  Google Titan USB-C (~35 €, nur FIDO2/U2F), Nitrokey 3C NFC (~60 €, DE, Open Source).
- **Backup-Key: Entscheidung abhängig vom Preis** (offen).
  - Mit nur 1 Key ist das Passwort-Fallback der einzige Rettungsanker bei Verlust/Defekt.
  - Empfehlung bei 2 Keys: beide Keys beim Enrollment gleich mit eintragen.

## Aktuelle Passwort-Fronten (nex)
| Schicht | Stand heute | Passkey machbar? |
|---|---|---|
| Greeter-Login (Noctalia Greeter / greetd) | Passwort via PAM | ✅ `pam_u2f` hybrid |
| Screen-Lock (`Mod+ALT+L`) | Passwort | ⚠️ PAM-Service von Noctalia prüfen |
| sudo | `wheelNeedsPassword = false` (passwortlos) | nicht nötig |
| LUKS (Boot) | keine Disk-Verschlüsselung | n/a (erst bei LUKS-Einführung) |
| SSH | kein SSH-Daemon auf nex | optional `sk-ssh-ed25519` |
| Browser (Firefox / WebAuthn) | — | ✅ OOTB |

## Design-Entscheidung
- **`pam_u2f` (Touch) hybrid** statt `pam_fido2` (Touch+PIN-Pflicht):
  `auth sufficient` → Key **oder** Passwort, kein Lockout-Risiko.

## Flake-Umsetzung (nur nex)
- Neues Modul **`modules/system/u2f-nex.nix`**, importiert **nur** in
  `hosts/nex/configuration.nix` (nicht `common.nix`).
  - `security.pam.services.greetd.u2fAuth = true;`
  - Screen-Lock: PAM-Service von Noctalia identifizieren, dort ebenfalls `u2fAuth`.
  - Pakete: `yubikey-manager`, `fido2-tools` (pam-u2f kommt via `security.pam`).
  - udev: FIDO2-Zugriff verifizieren (WebAuthn läuft OOTB; nur bei Bedarf
    `services.udev.packages = [ pkgs.u2f-hidraw-policy ]` + `u2f`-Gruppe).

## Einmaliges Setup (nach Kauf + Rebuild, manuell — bewusst NICHT in git)
1. Key-PIN setzen: `ykman fido access change-pin` (Pflicht für Passkeys).
2. Enrollment: `pamu2fcfg` → `~/.config/Yubico/u2f_keys` (mortiferus);
   bei 2 Keys beide Einträge hinein (Haupt + Backup).
3. Test: Greeter-Login per Berührung + WebAuthn (`webauthn.io`).

## Konten-Umstellung (nach erfolgreichem Login-Test)
- Firefox: Passkeys per WebAuthn an Konten anhängen (Google/Microsoft/GitHub/…),
  hybrid Passwort+Passkey, nach und nach.

## Optional später
- SSH: `ssh-keygen -t ed25519-sk -O resident` (erst wenn SSH-Server auf nex).
- LUKS + `systemd-cryptenroll` für Boot-Passkey (erst wenn Disk verschlüsselt wird).

## Offene Entscheidungen
- [ ] Backup-Key: 1× oder 2× (preisabhängig)?
- [ ] SSH-FIDO2 weglassen (kein SSH-Daemon auf nex)?
- [ ] `pam_u2f` hybrid bestätigt?
