-- home/plasma.nix's scripted parts: theme commands, panels, wallpaper and desktop widgets, run at Plasma login like plasma-manager.
local dir = ".local/share/archix-plasma/"

local themes = [[
#!/bin/sh
set -e
plasma-apply-desktoptheme sumac-night-plasma
plasma-apply-cursortheme WhiteSur-cursors --size 24
plasma-apply-colorscheme SummaculateNight
/usr/lib/plasma-changeicons Sumac-Night
]]

-- Each script runs once per content change; any changed script re-runs all of them, since the panel script wipes the widgets.
local run_all = [[
#!/bin/sh
dir="$HOME/.local/share/archix-plasma"
state="$HOME/.local/state/archix-plasma"
mkdir -p "$state"
changed() { [ "$(sha256sum < "$dir/$1")" != "$(cat "$state/$1" 2>/dev/null)" ]; }
mark() { sha256sum < "$dir/$1" > "$state/$1"; }
for js in "$dir"/*.js; do
  if changed "$(basename "$js")"; then rm -f "$state"/*.js; break; fi
done
if changed themes.sh && sh "$dir/themes.sh"; then mark themes.sh; fi
for js in "$dir"/*.js; do
  name=$(basename "$js")
  changed "$name" || continue
  [ "$name" = 2-panels.js ] && rm -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$js")" && mark "$name"
done
]]

local panels = [[
panels().forEach((panel) => panel.remove());

{
  const panel = new Panel();
  panel.height = 25;
  panel.floating = true;
  panel.alignment = "center";
  panel.location = "top";
  panel.lengthMode = "fill";

  panel.addWidget("org.kde.plasma.kickoff");

  var w = panel.addWidget("com.github.antroids.application-title-bar");
  w.currentConfigGroup = ["Appearance"];
  w.writeConfig("widgetButtonsAspectRatio", 100);
  w.writeConfig("widgetButtonsAuroraeTheme", "sumac-night-blur-small");
  w.writeConfig("widgetButtonsIconsTheme", 2);
  w.writeConfig("widgetButtonsMargins", 4);
  w.writeConfig("widgetElements", ["windowCloseButton", "windowMinimizeButton", "windowMaximizeButton", "windowTitle"]);
  w.writeConfig("widgetElementsDisabledMode", 2);
  w.writeConfig("widgetHorizontalAlignment", 1);
  w.writeConfig("widgetSpacing", 6);
  w.writeConfig("widgetVerticalAlignment", 128);
  w.writeConfig("windowTitleMaximumWidth", 320);

  panel.addWidget("org.kde.plasma.appmenu");
  panel.addWidget("org.kde.plasma.panelspacer");

  w = panel.addWidget("org.kde.plasma.systemtray");
  w.currentConfigGroup = ["General"];
  w.writeConfig("extraItems", ["org.kde.plasma.cameraindicator", "org.kde.plasma.devicenotifier", "org.kde.plasma.notifications", "org.kde.plasma.clipboard", "org.kde.plasma.manage-inputmethod", "org.kde.plasma.mediacontroller", "org.kde.plasma.keyboardlayout", "org.kde.plasma.battery", "org.kde.plasma.brightness", "org.kde.kscreen", "org.kde.plasma.volume", "org.kde.plasma.keyboardindicator", "org.kde.plasma.networkmanagement", "org.kde.plasma.printmanager"]);

  panel.addWidget("com.jaxparrow07.macoswidgets.weatherpanel");

  w = panel.addWidget("org.kde.plasma.digitalclock");
  w.currentConfigGroup = ["Appearance"];
  w.writeConfig("autoFontAndSize", true);
  w.writeConfig("dateDisplayFormat", 1);
  w.writeConfig("dateFormat", "shortDate");
  w.writeConfig("showDate", true);
  w.writeConfig("showSeconds", 0);
}

{
  const panel = new Panel();
  panel.height = 60;
  panel.floating = true;
  panel.alignment = "center";
  panel.hiding = "dodgewindows";
  panel.location = "bottom";
  panel.lengthMode = "fit";

  var w = panel.addWidget("org.kde.plasma.icontasks");
  w.currentConfigGroup = ["General"];
  w.writeConfig("fill", false);
  w.writeConfig("forceStripes", false);
  w.writeConfig("highlightWindows", true);
  w.writeConfig("launchers", ["applications:brave-browser.desktop", "applications:com.mitchellh.ghostty.desktop", "applications:org.gnome.Nautilus.desktop", "applications:hearth.desktop", "applications:spotify.desktop", "applications:org.kde.kcalc.desktop"]);
  w.writeConfig("showToolTips", true);
}
]]

local wallpaper = [[
for (const desktop of desktops()) {
  desktop.wallpaperPlugin = "org.kde.image";
  desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  desktop.writeConfig("Image", "file:///home/umceko/Pictures/Wallpapers/anime/general/goblin_slayer_1.jpg");
}
]]

-- Absolute pixels for a 1920x1200 screen; placement only takes at addWidget() time, hence two passes.
local function widgets(comment)
  return comment .. "\n" .. [[
var wanted = {
  "com.jaxparrow07.macoswidgets.weather":      [  80,   0, 384, 272],
  "com.jaxparrow07.macoswidgets.calendar":     [1472,   0, 384, 272],
  "com.jaxparrow07.macoswidgets.clock-square": [  96, 336, 160, 160],
  "com.jaxparrow07.macoswidgets.music":        [1360, 560, 480, 320]
};

var config = {
  "com.jaxparrow07.macoswidgets.weather": {
    "General": { "location": "Istanbul" }
  }
};

for (var d of desktops()) {
  for (var type in wanted) {
    var stale = d.widgets().filter(function (w) { return w.type === type; });
    for (var w of stale) { w.remove(); }
  }

  if (typeof d.screen === "number" && d.screen < 0) { continue; }

  for (var type in wanted) {
    var g = wanted[type];
    var w = d.addWidget(type, g[0], g[1], g[2], g[3]);

    var groups = config[type];
    if (!groups) { continue; }
    for (var group in groups) {
      w.currentConfigGroup = [group];
      for (var key in groups[group]) {
        w.writeConfig(key, groups[group][key]);
      }
    }
  }
}
]]
end

return {
  packages = {
    "qt6-tools",
    "sumac-theme",
    "liquidglass-kde-widgets",
    "application-title-bar",
    "whitesur-icon-theme",
    "whitesur-cursor-theme-git", -- check
  },
  home = {
    files = {
      [dir .. "themes.sh"] = { text = themes, executable = true },
      [dir .. "run_all.sh"] = { text = run_all, executable = true },
      [dir .. "2-panels.js"] = { text = panels },
      [dir .. "3-wallpaper.js"] = { text = wallpaper },
      [dir .. "4-desktop-widgets.js"] = { text = widgets("// Pass 1: make sure all four exist. Positions cascade here.") },
      [dir .. "5-desktop-widget-positions.js"] = { text = widgets("// Pass 2: re-place each one into the now-settled layout.") },
      [".config/autostart/archix-plasma.desktop"] = {
        text = "[Desktop Entry]\nType=Application\nName=archix Plasma layout\nExec=/home/umceko/.local/share/archix-plasma/run_all.sh\nX-KDE-autostart-condition=ksmserver\n",
      },
      [".local/share/applications/rofi-emoji.desktop"] = {
        text = "[Desktop Entry]\nType=Application\nName=Emoji Picker\nExec=rofi -modi emoji -show emoji\nNoDisplay=true\nStartupNotify=false\n",
      },
    },
  },
}
