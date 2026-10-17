# Conversion notes: NixOS `desktop` → archix

Source: `~/nixos` (flake host `nixos`: `hosts/desktop`, the shared `modules/`, `home/` and `pkgs/`). Target: CachyOS znver4, `linux-cachyos`, systemd-boot, btrfs root. `hosts/elitebook` was not converted.

| Nix | archix |
| --- | --- |
| `modules/common.nix` | `lua/modules/base.lua`, `networking.lua` |
| `modules/desktop.nix`, `dms.nix`, `keyring.nix`, `nvim-lsp.nix`, `packages.nix`, `syncthing.nix`, `vice.nix` | `desktop.lua`, `dms.lua`, `keyring.lua`, `dev.lua`, `packages.lua`, `syncthing.lua`, `vice.lua` (a typed module) |
| `hosts/desktop/*.nix` | `lua/hosts/desktop.lua` + `gaming`, `peripherals`, `vr`, `drives`, `tweaks`, `nginx`, `zapret`, `dns`, `desktop_home` |
| `home/common.nix`, `claude.nix`, `plasma.nix` | `home.lua`, `claude.lua`, `plasma.lua` + `plasma_rc.lua` |
| `pkgs/*.nix` | `pkgbuilds/` (or the AUR, see below) |
| `config/` (the `mkOutOfStoreSymlink` dirs) | copied to `config/`; `live = true` links |

## 1. Not converted, or converted approximately

**Dropped because they're Nix-only**
- `nix.settings` (jobs, substituters, http2, gc, optimise, min/max-free), `nixpkgs.config` (allowUnfree, `permittedInsecurePackages` electron-39.8.10), `stateVersion`s, `home-manager.*`, `comma`, HM's `LOCALE_ARCHIVE` / fontconfig / `tray.target` files.
- `boot.initrd.availableKernelModules` (mkinitcpio's autodetect covers them) and `kvm-amd` (autoloaded).
- Workarounds for Nix limits: the typescript-language-server pnpm hash, t3code's rpath `postFixup`, prismlauncher's `libxkbcommon`, the forge-tcmalloc `ldconfig` shim (now just `gperftools` + `bc`), compiling `git-credential-libsecret` (Arch's git ships it in `/usr/lib/git-core`), the store-path `substituteInPlace` on DMS's pam files, the one-off `claudeMcpAdopt` hook, `programs.appimage.binfmt` (`fuse2` is enough on Arch).
- `programs.chromium.extensions`: no effect on NixOS, because `programs.chromium.enable` was never set.
- `hyproled`: commented out in the Nix config.
- `antigravity-acp`: there's no Arch or AUR package.
- `matlab-language-server`: the AUR package depends on MATLAB itself (matlab-meta and matlab-mpm, tens of GB), unlike nixpkgs'.
- `rust-analyzer`: `rustup` provides it and conflicts with the package. Use `rustup component add rust-analyzer`.

**Approximations**
- Kernel: `linuxPackages_latest` becomes `linux-cachyos` + `linux-cachyos-nvidia-open`. v4l2loopback 0.15.4 becomes `v4l2loopback-dkms` (0.15.4 in extra; builds against `linux-cachyos-headers`).
- chaotic-nyx `proton-cachyos_x86_64_v3` becomes CachyOS's `proton-cachyos-slr`.
- The **nixpkgs-scx pin** isn't carried over. Arch's `scx-scheds` is 1.1.3, the release the pin avoided (32-45 s stalls and watchdog reboots on kernel 7.2, sched-ext/scx#3750). Before relying on `scx.service`, pin 1.1.2 in `archix.lock` or disable `scx.service`.
- lanzaboote: `boot.entries = 10`, and `boot.secure_boot` is left automatic (it signs once `/var/lib/sbctl` has keys).
- `networking.firewall.extraCommands` (the `ts-input`/`ts-forward`/`ts-postrouting` jumps that skip `wt0`): nftables can't jump into another table, so `ts-netfilter-jumps.service` runs the same iptables (nft backend) commands after tailscaled starts. `tailscale0`, `wt0` and `virbr0` are trusted interfaces, because on NixOS their own chains accepted traffic before `nixos-fw` did. UDP 41641 is open, as `ts-input` allowed it.
- zapret: the module's ip46tables NFQUEUE rules become an nftables `postrouting` chain in `firewall.extra_rules` (checked with `nft -c`). The unit replaces zapret-git's own `zapret.service` and runs `/usr/bin/nfqws`.
- Firewall ports come from NixOS module defaults: sshd 22, avahi 5353, KDE Connect 1714-1764, Steam, Syncthing, WiVRn 9757, NetBird 51820.
- `services.tailscale.extraSetFlags` (common + desktop) becomes a `tailscale.set_flags` option and the `tailscale_set` hook. It runs on every switch, not at every boot.
- `services.syncthing.settings` becomes a hook that posts devices and folders to the REST API, as NixOS's `syncthing-init` does. An `STHOMEDIR` drop-in keeps `~/.config/syncthing`. The device key `nixos` is renamed `desktop`.
- The `dms-settings` git filter (home-manager set it on NixOS) is `scripts/dms-settings-clean`. After cloning, run `git config filter.dms-settings.clean scripts/dms-settings-clean`.
- Strict DoT: `networking.networkmanager.connectionConfig` with `ipv4.ignore-auto-dns` never applied (NetworkManager logs "unknown key" for it). NixOS only works because the `eno1` profile was edited by hand. NetworkManager now runs with `dns=none` and `systemd-resolved=false` (the latter pushes link DNS even with `dns=none`), so no profile can hand resolved a link DNS server that bypasses DoT.
- NetBird: `netbird@default.service`, with `DisableDNS`/`DisableClientRoutes` merged into `/etc/netbird/config.json`. **Check the path**: the AUR unit starts `netbird service run` without `--config`.
- PAM: `/etc/pam.d/sddm` (Arch's file minus `pam_kwallet5`) and `/etc/pam.d/login` (adds gnome-keyring) are written whole. Arch's `kde` stack has no kwallet lines, so it's left as is.
- SDDM: `DefaultSession=hyprland-uwsm.desktop`, Wayland greeter on kwin (the compositor plasma6 picks on NixOS).
- Plymouth: the package plus `splash`. **Check** that `plymouth` is in mkinitcpio's `HOOKS`.
- `cpuFreqGovernor` becomes `cpufreq.service` (cpupower). `zramSwap` becomes `/etc/systemd/zram-generator.conf`. `systemd.oomd` becomes slice drop-ins, as the NixOS module renders them.
- Swap file: `/var/lib/swapfile` becomes `/swap/swapfile` in its own btrfs subvolume, created by the `swapfile` hook, because a swap file inside `@` blocks archix's root snapshots.
- `services.ananicy.settings` becomes a whole `/etc/ananicy.d/ananicy.conf` (ananicy-cpp defaults + `cgroup_realtime_workaround = false`). **Check** it against the file cachyos-ananicy-rules ships.
- `igc-resume`: the `;`-joined `ExecStart` is split into two `ExecStart` lines.
- `programs.gamescope.capSysNice` and `programs.gpu-screen-recorder` become `setcap` hooks (package updates drop the caps; the hooks restore them on the next switch).
- `hardware.openrazer.users` becomes the `plugdev` group (Arch's convention). OpenRGB's server unit and i2c modules are written out as NixOS does.
- NVIDIA: `nvidia-drm.modeset/fbdev`, `NVreg_PreserveVideoMemoryAllocations`, nvidia-suspend/resume/hibernate and acpid, all copied from NixOS's nvidia module.
- Memtest: `memtest86+-efi` + a hand-written `/boot/loader/entries/memtest86+.conf`. **Check** that archix's boot-entry handling leaves it alone.
- Plasma: plasma-manager's `configFile` and high-level options become kconfig `merge`s, generated from plasma-manager's rendered `data.json`. Keys stay unlocked, as in plasma-manager; `lock` in `plasma_rc.lua` adds `[$i]`. `kuriikwsfilterrc` `DefaultWebShortcut` (which plasma-manager deletes) isn't reproduced. The theme commands, panels, wallpaper and the two desktop-widget scripts run from `~/.local/share/archix-plasma` through an autostart entry, once per change, as plasma-manager's `run_all.sh` did.
- oh-my-zsh: archix's zsh module doesn't support it. `oh-my-zsh-git` is sourced from `init_content`, which archix places after the starship and kitty integration. The history values are set again after it, and `enable_completion = false` because OMZ runs compinit itself.
- DMS assets: dms-shell ≥ 1.6 ships no QML assets, so the `dms_clone_assets` hook clones DankMaterialShell at the installed version (needs network once per version).
- proton-cachyos: the writable copy BSManager needs is refreshed only when the package changes. Steam may list both copies.
- `~/.claude.json`: `args = []` / `env = {}` are left out (archix merges an empty Lua table as a JSON object).
- `daemon.json`, `.claude.json`, NetBird's config and the KDE rc files are `merge`s: only the declared keys are set.
- HUSH: `LD_LIBRARY_PATH` without `/run/opengl-driver/lib`. WiVRn: `autoStart` was off, so only the packages and firewall ports are set.
- `config/hypr/lua/env.lua` and `config/niri/config.kdl`: in the copies, the NixOS `XDG_DATA_DIRS` entries are replaced with `/usr/local/share:/usr/share`. The stray `config/nvim/nvim` store symlink was not copied.
- `patches`: hyprland (dry-run applies cleanly to 0.56.2) and quickshell (0.3.2) patch Arch's recipe. Both packages are also in `cachyos-extra-znver4`, which comes before the official repos. **Check** which one the lock picks.
- `vice-clipper` is built from the pinned commit plus the clipboard patch. The repo moved from eklonofficial/Vice to splitshotz/Vice; the AUR package of the same name tracks releases without the patch.

## 2. Package-name guesses (`-- check`)

`gamescope-session-steam-git` (CachyOS also has `gamescope-session-cachyos`), `proton-cachyos-slr` (vs `proton-cachyos-native`), `r2modman-bin`, `alvr`, `ttf-ubuntu-sans` (nixpkgs `ubuntu-sans`; `ttf-ubuntu-font-family` is the old font), `wooting-udev`, `whitesur-cursor-theme-git`, `gpustat-git` (arduano's gpustat), `mongosh-bin`, `android-apktool`, `jdk-temurin`, `flutter-bin`, `valkey` (for nixpkgs `redis`; provides it), `torbrowser-launcher`, `spotify` (AUR, for `spotify.desktop` in the dock), `rustdesk-bin`, `bibata-cursor-theme`, `python-pywal`, `vscode-langservers-extracted`, `postgres-language-server-bin`, and `rootflags=subvol=/@`.

Local PKGBUILDs (git sources pinned by commit or tag, so `sha256sums=('SKIP')`, as Arch does for VCS sources; nixpkgs' `fetchFromGitHub` NAR hashes can't be converted): `application-title-bar`, `sumac-theme`, `liquidglass-kde-widgets`, `hypr-computer-mcp`, `headless-computer-mcp`, `vice-clipper`, `hearth-bin` (deb sha256 from the GitHub release). Taken from the AUR instead of a PKGBUILD: `photocraft-bin`, `iriunwebcam-bin` (2.9.3 vs Nix's 2.9.1), `wooting-bg-service`, `chatmixd-git`, `hush-mic`, `zapfast`, `opencomposite-git`.

## 3. To do by hand

- Replace the `root=UUID=...` placeholder in `lua/hosts/desktop.lua` (and check `rootflags`) after installing.
- Hostname: Hyprland (`config/hypr/lua/host.lua`, `is_desktop = name == "nixos"`), `DankMaterialShell/hosts/nixos.json` and `niri/hosts/nixos.kdl` all read `/etc/hostname`. Either name the machine `nixos` at install or rename those three.
- Run `passwd umceko`. archix never manages passwords.
- Copy over state and secrets that aren't in this config: `/var/lib/sbctl` (Secure Boot keys, lanzaboote's `pkiBundle`), `~/.config/syncthing` (`key.pem`/`cert.pem` keep device ID `BNVEMQD-…`), `~/.local/share/keyrings` (the gnome-keyring login keyring), `~/.ssh`, `~/.gnupg`, `~/.config/gh`, `~/.claude*`.
- Log in to Tailscale (`tailscale up`, then approve the exit node in the admin console), NetBird (setup key) and Mullvad.
- Pin `scx-scheds` 1.1.2 (see above).
- `lua/modules/repos.lua` declares CachyOS's repos. Drop it if `archix init` already declared them.
- Git: this repo's `.gitattributes` uses the `dms-settings` clean filter, which `programs.git` points at `~/.local/bin/dms-settings-clean`.
