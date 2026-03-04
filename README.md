# FixVR

A tiny udev rule that fixes the Valve Index blank EDID bug on Linux, stops the kernel from seeing your HMD as a 640×480 monitor.

## The Problem

On some kernels/driver versions the Valve Index HMD enumerates with a blank EDID, causing the display subsystem to fall back to 640×480. The headset works, but SteamVR and compositors cannot use the correct resolution or refresh rate.

## The Fix

A udev rule sends a 64-byte HID reboot payload (`\x16\x01` + zeroes) to the `hidraw` device node the first time the HMD is detected each boot. This forces the firmware to re-enumerate and expose the correct EDID.

A flag file in `/tmp` prevents the command from being sent more than once per session. Because `/tmp` is cleared on boot it always runs fresh on the next power-on.

## Installation

### Automatic (any distro)

```bash
curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/install.sh | bash
```

The script auto-detects your distro:
- **Arch / Manjaro / EndeavourOS / …** → installs the `fixvr` AUR package via `paru` or `yay` (offers to install paru if neither is present)
- **Everything else** → copies the rule file to `/etc/udev/rules.d/` and reloads udev

### Manual

```bash
sudo curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/99-valve-index-reboot.rules \
  -o /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --subsystem-match=hidraw
```

Reconnect your Valve Index and you're done.

## Uninstall

```bash
sudo rm /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
```

## License

MIT
