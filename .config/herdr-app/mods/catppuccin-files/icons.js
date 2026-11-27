// Picks a Catppuccin VS Code icon for a file or folder, the way VS Code's file
// icon themes do: the longest match on the name wins, then the default icon.

import { settings, theme } from "herdr";
import { fileExtensions, fileNames, folderNames } from "./icon-map.js";

// The icons have their colors built in, one set per flavor. A flavor is known by
// its Base color; any other theme gets the set the layout would show for its
// appearance.
const FLAVORS = { "#eff1f5": "latte", "#303446": "frappe", "#24273a": "macchiato", "#1e1e2e": "mocha" };

function flavor() {
  return FLAVORS[theme().background?.toLowerCase()] ?? (settings().dark ? "macchiato" : "latte");
}

const url = icon => `mods/catppuccin-files/icons/${flavor()}/${icon}.svg`;

function fileIconName(path) {
  const parts = path.toLowerCase().split(/[\\/]/), name = parts.pop(), parent = parts.pop();
  // Associations can name a parent folder, like workflows/yml.
  const lookup = (map, key) => (parent && map.get(`${parent}/${key}`)) || map.get(key);
  const named = lookup(fileNames, name);
  if (named) return named;
  // a.test.ts tries test.ts, then ts. A dotfile's own name counts: .gitignore tries gitignore.
  for (let dot = name.indexOf("."); dot >= 0; dot = name.indexOf(".", dot + 1)) {
    const icon = lookup(fileExtensions, name.slice(dot + 1));
    if (icon) return icon;
  }
  return "_file";
}

export const fileIcon = path => url(fileIconName(path));

export function folderIcon(path, open) {
  const name = path.toLowerCase().split(/[\\/]/).pop();
  return url(`${folderNames.get(name) ?? "_folder"}${open ? "_open" : ""}`);
}
