-- modules/keyring.nix: gnome-keyring is the only Secret Service; kwallet stays out of the login stacks.
local flags = { text = "--password-store=gnome-libsecret\n" }

return {
  packages = { "gnome-keyring", "libsecret" },
  files = {
    ["/etc/pam.d/sddm"] = {
      text = [[
#%PAM-1.0

auth       include   system-login
-auth      optional  pam_gnome_keyring.so

account    include   system-login

password   include   system-login
-password  optional  pam_gnome_keyring.so use_authtok

session    optional  pam_keyinit.so force revoke
session    include   system-login
-session   optional  pam_gnome_keyring.so auto_start
]],
    },
    ["/etc/pam.d/login"] = {
      text = [[
#%PAM-1.0

auth       requisite  pam_nologin.so
auth       include    system-local-login
-auth      optional   pam_gnome_keyring.so
account    include    system-local-login
session    include    system-local-login
-session   optional   pam_gnome_keyring.so auto_start
password   include    system-local-login
]],
    },
  },
  home = {
    files = {
      -- Chromium picks its key store from XDG_CURRENT_DESKTOP, so Plasma and Hyprland logged each other out.
      [".config/brave-flags.conf"] = flags,
      [".config/chrome-flags.conf"] = flags,
      [".config/chromium-flags.conf"] = flags,
    },
  },
}
