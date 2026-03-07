# FixVR

A tiny udev rule that fixes the Valve Index blank EDID bug on Linux, stops the kernel from seeing your HMD as a 640×480 monitor.

## The Problem

On some kernels/driver versions the Valve Index HMD enumerates with a blank EDID, causing the display subsystem to fall back to 640×480. The headset works, but SteamVR and compositors cannot use the correct resolution or refresh rate.

## The Fix

A udev rule sends a 64-byte HID reboot payload (`\x16\x01` + zeroes) to the `hidraw` device node the first time the HMD is detected each boot. This forces the firmware to re-enumerate and expose the correct EDID.

A flag file in `/tmp` prevents the command from being sent more than once per session. Because `/tmp` is cleared on boot it always runs fresh on the next power-on.

## Installation

Take a look into the [docs](https://fixvr.miguvt.com/install) for automatic installation scripts for Arch (AUR) and NixOS, or follow the manual instructions for any distro that is in the same page.

## License

MIT
