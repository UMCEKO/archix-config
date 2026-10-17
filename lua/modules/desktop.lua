-- modules/desktop.nix plus common.nix's SDDM/Plasma session: Hyprland (patched), niri, portals, fonts, Qt theming.
local function portals(t)
  local lines = { "[preferred]" }
  for _, k in ipairs { "default", "org.freedesktop.impl.portal.Access", "org.freedesktop.impl.portal.FileChooser", "org.freedesktop.impl.portal.Notification", "org.freedesktop.impl.portal.ScreenCast", "org.freedesktop.impl.portal.Screenshot", "org.freedesktop.impl.portal.Secret" } do
    if t[k] then lines[#lines + 1] = k .. "=" .. table.concat(t[k], ";") end
  end
  return table.concat(lines, "\n") .. "\n"
end

return {
  packages = {
    "sddm",
    "plasma-meta",
    "kdeconnect",
    "xorg-xwayland",
    "mesa",
    "lib32-mesa",
    "vulkan-radeon",
    "lib32-vulkan-radeon",
    "hyprland",
    "xdg-desktop-portal-hyprland",
    "uwsm",
    "niri",
    "xdg-desktop-portal-gnome",
    "xdg-desktop-portal-gtk",
    "kvantum",
    "kvantum-qt5",

    "ttf-ubuntu-sans", -- check
    "ttf-ubuntu-nerd",
    "ttf-fira-sans",
    "ttf-fira-code",
    "ttf-firacode-nerd",
    "ttf-roboto",
    "ttf-jetbrains-mono-nerd",
    "ttf-meslo-nerd",
    "otf-font-awesome",
    "noto-fonts",
    "noto-fonts-cjk",
    "noto-fonts-emoji",
    "ttf-dejavu",
    "ttf-liberation",
    "ttf-opensans",
    "cantarell-fonts",
    "ttf-poppins",
    "ttf-hack",
    "ttf-fantasque-nerd",
    "ttf-carlito",
  },

  -- programs.hyprland.package's overrideAttrs patch, rebuilt from Arch's recipe.
  patches = { hyprland = { "patches/hyprland-scroll-move-mouse-drag.patch" } },

  services = { ["sddm.service"] = true },

  environment = {
    variables = { QT_QPA_PLATFORMTHEME = "kde", QT_STYLE_OVERRIDE = "kvantum" },
  },

  files = {
    ["/etc/sddm.conf.d/10-archix.conf"] = {
      text = archix.formats.ini {
        General = {
          DefaultSession = "hyprland-uwsm.desktop",
          DisplayServer = "wayland",
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell",
        },
        Wayland = { CompositorCommand = "kwin_wayland --no-global-shortcuts --no-kactivities --no-lockscreen --locale1" },
      },
    },
    ["/etc/X11/xorg.conf.d/00-keyboard.conf"] = {
      text = 'Section "InputClass"\n  Identifier "system-keyboard"\n  MatchIsKeyboard "on"\n  Option "XkbLayout" "us"\nEndSection\n',
    },
    ["/etc/xdg/xdg-desktop-portal/hyprland-portals.conf"] = {
      text = portals {
        default = { "hyprland", "gtk" },
        ["org.freedesktop.impl.portal.Secret"] = { "gnome-keyring" },
        ["org.freedesktop.impl.portal.ScreenCast"] = { "hyprland" },
        ["org.freedesktop.impl.portal.Screenshot"] = { "hyprland" },
        ["org.freedesktop.impl.portal.FileChooser"] = { "gtk" },
      },
    },
    ["/etc/xdg/xdg-desktop-portal/niri-portals.conf"] = {
      text = portals {
        default = { "gnome", "gtk" },
        ["org.freedesktop.impl.portal.Access"] = { "gtk" },
        ["org.freedesktop.impl.portal.FileChooser"] = { "gtk" },
        ["org.freedesktop.impl.portal.Notification"] = { "gtk" },
        ["org.freedesktop.impl.portal.Secret"] = { "gnome-keyring" },
      },
    },
    -- Unifont's hex-box glyphs showed up as garbage in Discord.
    ["/etc/fonts/local.conf"] = {
      text = [[
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <rejectfont>
      <pattern>
        <patelt name="family"><string>Unifont</string></patelt>
      </pattern>
    </rejectfont>
  </selectfont>
</fontconfig>
]],
    },
  },
}
