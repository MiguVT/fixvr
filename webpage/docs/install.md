# Installation

fixvr ships a single udev rule file (`99-valve-index-reboot.rules`) and a helper install script.  
Pick the method that matches your distro. 


## Automatic - install script

The easiest way on any distro. Clone the repo and run the script:

```bash
curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/install.sh | bash
```

The script auto-detects your distro:

| Distro family | What happens |
|---|---|
| Arch / Manjaro / EndeavourOS / Garuda | Installs the `fixvr` AUR package via **paru** or **yay** |
| Debian / Ubuntu / Mint / Pop!_OS | Copies the rule and reloads udev |
| Fedora / RHEL / openSUSE / any other | Copies the rule and reloads udev |

> **AUR helper** — If neither `paru` nor `yay` is found, the script will offer to install paru for you.


## Arch-based (AUR)

Install with your preferred AUR helper:

::: code-group

```bash [paru]
paru -S fixvr
```

```bash [yay]
yay -S fixvr
```

:::


## Manual (all distros)

Download and install the rule file, then reload udev:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/99-valve-index-reboot.rules \
  -o /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --subsystem-match=hidraw
```

Reconnect your Valve Index — the fix is now active.


## Uninstall

```bash
sudo rm /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
```

On Arch (AUR):

```bash
paru -R fixvr   # or: yay -R fixvr
```


## How it works

The udev rule matches the Valve Index HMD by its USB vendor/product ID (`28de:2300`). On the `add` event — i.e. each time the device is enumerated — it runs a short shell one-liner:

1. Checks for a flag file `/tmp/.valve-index-rebooted`.
2. If the flag is absent, it writes a 64-byte HID reboot payload (`\x16\x01` followed by zeroes) directly to the `hidraw` device node, then creates the flag file.
3. The HMD reboots its HID layer, re-reads the EDID correctly, and presents itself at the right resolution.

Because `/tmp` is cleared every boot, the flag is always absent on the first plug-in of each session, and always present for subsequent plug-ins, preventing double-reboots.
