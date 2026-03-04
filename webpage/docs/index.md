---
layout: home

hero:
  name: "FixVR"
  text: "Index isn't a monitor"
  tagline: A tiny udev rule that cures the blank EDID bug - no more kernel seeing your HMD as a 640×480 monitor.
  actions:
    - theme: brand
      text: Install Now
      link: /install
    - theme: alt
      text: View on GitHub
      link: https://github.com/miguvt/fixvr

features:
  - icon: 🔌
    title: Blank EDID Fix
    details: The Valve Index HMD sometimes enumerates with a blank EDID, causing the kernel to fall back to a 640×480 resolution. This rule sends a HID reboot command the first time the device is plugged in each boot, forcing the correct EDID to be read.

  - icon: ⚡
    title: One-shot per Boot
    details: A flag file in /tmp ensures the reboot command is sent only once per session. Because /tmp is cleared on each boot, the fix is always applied when needed - and never applied twice in one session.

  - icon: 🐧
    title: Works on Any Distro
    details: Plain udev rules work everywhere Linux does - Arch, Fedora, Debian, Ubuntu, openSUSE, and more. The install script handles each distro automatically, including AUR installation on Arch-based systems.

  - icon: 🪶
    title: Zero Dependencies
    details: No daemons, no background services, no kernel modules. Just a single udev rule file that works with the Linux hardware stack you already have.
---
