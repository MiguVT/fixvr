# Installation

FixVR ships a single udev rule file (`99-valve-index-reboot.rules`) and a helper install script.  
Pick the method that matches your distro. 


## Automatic - install script

The easiest way on any distro. run this script:

```bash
curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/install.sh | bash
```

The script auto-detects your distro:

| Distro family | What happens |
|---|---|
| Arch / Manjaro / EndeavourOS / Garuda | Installs the `fixvr-git` AUR package via **paru** or **yay** |
| Debian / Ubuntu / Mint / Pop!_OS | Copies the rule and reloads udev |
| Fedora / RHEL / openSUSE / any other | Copies the rule and reloads udev |

> **AUR helper** — If neither `paru` nor `yay` is found, the script will offer to install paru for you.


## Arch-based (AUR)

Install with your preferred AUR helper:

::: code-group

```bash [paru]
paru -S fixvr-git
```

```bash [yay]
yay -S fixvr-git
```

:::


## NixOS

NixOS manages udev rules declaratively. Add the following to your system configuration (e.g. `configuration.nix` or a dedicated module):

```nix
{ pkgs, ... }:
{
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2300", ACTION=="add", RUN+="/bin/sh -c '(sleep 2; test -f /tmp/.valve-index-rebooted || { printf \"\\x16\\x01\" | cat - /dev/zero | head -c 64 > /dev/%k && touch /tmp/.valve-index-rebooted; }) &'"
  '';
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```


## Manual (all distros)

Download and install the rule file, then reload udev:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/99-valve-index-reboot.rules \
  -o /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=hidraw
```

Reconnect your Valve Index — the fix is now active.


## Uninstall

```bash
sudo rm /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
```

On Arch (AUR):

```bash
paru -R fixvr-git   # or: yay -R fixvr-git
```

On NixOS, remove the `services.udev.extraRules` block and run `sudo nixos-rebuild switch`.


## How it works

The udev rule matches the Valve Index HMD by its USB vendor/product ID (`28de:2300`). On the `add` event — i.e. each time the device is enumerated — it fires a backgrounded shell one-liner:

1. A subshell is spawned in the background (`&`) so udev's event queue is not blocked.
2. After a 2-second delay (giving the HMD firmware time to finish initialising), it checks for a flag file `/tmp/.valve-index-rebooted`.
3. If the flag is absent, it writes a 64-byte HID reboot payload (`\x16\x01` followed by zeroes) directly to the `hidraw` device node.
4. Only if the write succeeds (`&&`), the flag file is created — this prevents the flag from being set when udev tries a wrong `hidraw` interface.
5. The HMD reboots its HID layer, re-reads the EDID correctly, and presents itself at the right resolution.

Because `/tmp` is cleared every boot, the flag is always absent on the first plug-in of each session, and always present for subsequent plug-ins, preventing double-reboots.


## Troubleshooting

### The fix doesn't seem to apply on boot

Make sure the rule file is installed and udev has been reloaded:

```bash
cat /etc/udev/rules.d/99-valve-index-reboot.rules
sudo udevadm control --reload-rules
```

Reconnect your headset or trigger manually:

```bash
sudo rm -f /tmp/.valve-index-rebooted
sudo udevadm trigger --action=add --subsystem-match=hidraw
sleep 4
ls -l /tmp/.valve-index-rebooted
```

If the flag file exists, the rule fired successfully.

### The flag file exists but the headset still shows as 640×480

This sometimes happens if the timing is tight. Try increasing the sleep value in the rule from `2` to `5` and rebooting.
