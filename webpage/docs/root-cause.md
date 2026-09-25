# The real root cause

::: tip Short version
The Valve Index bug was **not** really a blank-EDID bug that needed the headset
rebooted. It was `ddcutil` / `libddcutil` probing the headset and wedging its
EDID EEPROM. That probe is fixed upstream in **ddcutil 3.0.2** (and the config
file workaround below covers older versions). The fixvr udev rule is now a
**legacy fallback**.
:::

## What was actually happening

`ddcutil` reads DDC/CI data over the display's I2C bus to find out whether a
display supports things like brightness control. When it probes the Valve Index
(a DisplayPort sink flagged `non-desktop`), the headset firmware stops answering
EDID reads after the access to I2C slave address `0x37`.

Once that happens the kernel logs `EDID err: 2` / `EDID_NO_RESPONSE`, `amdgpu`
falls back to a safe `640×480` mode with `non-desktop=0`, and the headset is
unusable until it is power-cycled. Rebooting the HID layer (what fixvr did) got
the EDID back, but it treated the symptom, not the cause.

## Why only some setups were affected

The root cause is only triggered when something actually runs a DDC/CI probe
against the headset. The most common trigger is **KDE Plasma's `powerdevil`**
(the process behind *System Settings → Power Management / power consumption
settings*), which uses `libddcutil` to work out whether connected displays allow
brightness control. `powerdevil` probes at boot and login, which is exactly when
people saw the headset come up wrong or the system lock up.

So the bug was **never universal**: people who did not run KDE Plasma, or who did
not have `powerdevil`/`ddcutil` talking to the headset, often never saw it at
all. That is also why fixvr "helped" some people and not others — it was racing
another piece of software.

## The upstream fix

The issue was tracked in ddcutil as
[rockowitz/ddcutil#632](https://github.com/rockowitz/ddcutil/issues/632) and
fixed in [PR #637](https://github.com/rockowitz/ddcutil/pull/637), released in
**ddcutil 3.0.2**.

ddcutil now ships a built-in ignore list that includes the Valve Index HMD
(`VLV` / product `0x91a8`, model `Index HMD`). It is equivalent to the manual
option:

```
--ignore-mmid VLV-Index_HMD-37288
```

**Huge thanks to [@omus](https://github.com/omus)**, who diagnosed the root
cause, drove the upstream ddcutil fix, and pointed fixvr users at it. 🎉

## What you should do

### 1. Update ddcutil / libddcutil to 3.0.2 or newer

This is the real fix and needs no config file. Make sure your distro package (or
your `libddcutil` shared library, which is what `powerdevil` actually loads) is
at `3.0.2` or later:

```bash
ddcutil --version
```

Then restart `powerdevil` (or log out/in) so it picks up the new library. The
Valve Index should now be ignored by `libddcutil`.

### 2. Manually configure ddcutil ignore rules (if you cannot update ddcutil)

On ddcutil versions older than `3.0.2`, tell the library to ignore the headset
through the [`ddcutilrc` config file](https://www.ddcutil.com/config_file/).
`libddcutil` reads this, so `powerdevil` honours it after a restart:

```bash
mkdir -p ~/.config/ddcutil
cat >~/.config/ddcutil/ddcutilrc <<EOF
[global]
options = --ignore-mmid VLV-Index_HMD-37288
EOF
```

### 3. Verify ddcutil is ignoring your headset

Run `ddcutil detect` with the headset plugged in to verify the ignore rule is
working. Find the entry for the Valve Index which should look similar to:

```
DDC_disabled
   I2C bus:  /dev/i2c-6
   DRM_connector:           card0-DP-1
   EDID synopsis:
      Mfg id:               VLV - Valve Corporation
      Model:                Index HMD
      Product code:         37288  (0x91a8)
      Serial number:
      Binary serial number: 4294967295 (0xffffffff)
      Model year:           2018
   DDC communication disabled
```

If the output for `ddcutil detect` says "Invalid display" instead of
"DDC_disabled" as shown in the example then the ignore rule didn't work for
your exact model. To fix the ignore rule follow the steps in
["Manually configure ddcutil ignore rules"](#2-manually-configure-ddcutil-ignore-rules-if-you-cannot-update-ddcutil)
and update the `--ignore-mmid` to use the "Mfg id", "Model", and
"Product" shown in the `ddcutil dectect` output with your headsets details.

Additionally, [comment on this issue](https://github.com/rockowitz/ddcutil/issues/632)
with your headset's `--ignore-mmid` value so we can update `ddcutil` to ignore
your model by default.

### 4. (Optional) Stop the Index waking the system on suspend

Separate from the EDID wedge, the headset can wake the machine from suspend.
Tell the kernel to ignore its remote-wakeup capability by adding this kernel
parameter:

```
usbcore.quirks=28de:2613:j
```

Add it to your bootloader's kernel command line (`grub`/`systemd-boot`/
`limine`/etc.) and reboot. @omus is working on a [kernel patch](https://lore.kernel.org/all/20260924034200.421686-1-curtis.vogt@gmail.com/T/#u)
so this will eventually no longer be needed either.

## Do I still need fixvr?

Probably not. If your `libddcutil` is `3.0.2+` and you added the kernel quirk,
the headset should stop wedging and fixvr has nothing left to do.

The udev rule is kept as a **legacy fallback** for systems that cannot update
ddcutil, or that hit a genuinely separate EDID problem. Be aware that it reboots
the headset at boot, which can interact badly with other early-boot software
(for example it can [hang boot under Plymouth](https://github.com/MiguVT/fixvr/issues/6)),
and it does not run on resume from suspend
([issue #2](https://github.com/MiguVT/fixvr/issues/2)). That is why the root fix
is preferred.

See [Installation](/install) if you still want the legacy rule.

## References

- [ddcutil #632 — DDC/CI probing wedges a Valve Index HMD](https://github.com/rockowitz/ddcutil/issues/632)
- [ddcutil #637 — Add built-in ignore list which includes Valve Index](https://github.com/rockowitz/ddcutil/pull/637)
- [SteamVR-for-Linux #939 — Valve Index stops answering EDID after a read to `0x37`](https://github.com/ValveSoftware/SteamVR-for-Linux/issues/939)
- [fixvr #5 — Valve Index may soon no longer require fixvr](https://github.com/MiguVT/fixvr/issues/5)
- [fixvr #6 — fixvr can interact poorly with Plymouth resulting in a hung boot](https://github.com/MiguVT/fixvr/issues/6)
