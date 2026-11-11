#!/bin/bash

# Symlink every file tracked in this repo's config/ into ~/.config,
# plus named bin files into ~/.local/bin. Repo files win; existing
# targets are replaced silently.
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
configSrc="${baseDir}/config"
binSrc="${baseDir}/bin"

# only these repo/bin/* entries are linked into ~/.local/bin
binFiles=("dev-container")

link_file() {  # $1=src $2=dest
    mkdir -p "$(dirname "$2")"
    [ -L "$2" ] || rm -rf "$2"
    ln -sfn "$1" "$2"
}

echo "Linking ${configSrc} -> $HOME/.config"
find "$configSrc" -type f ! -name '.*' | while read -r src; do
    link_file "$src" "$HOME/.config/${src#"$configSrc"/}"
done

mkdir -p "$HOME/.local/bin"
for f in "${binFiles[@]}"; do
    if [ -f "${binSrc}/${f}" ]; then
        echo "Linking ${binSrc}/${f} -> $HOME/.local/bin/${f}"
        link_file "${binSrc}/${f}" "$HOME/.local/bin/${f}"
    else
        echo "Skipping ${f}: not found in ${binSrc}" >&2
    fi
done

# remove stale links pointing into this repo whose source no longer exists
find "$HOME/.config" -xtype l 2>/dev/null | while read -r link; do
    case "$(readlink -f "$link")" in
        "$configSrc"/*) rm -f "$link" ;;
    esac
done

echo "Done. Links:"
find "$HOME/.config" -type l -lname "${configSrc}/*" -printf '  %p\n'
for f in "${binFiles[@]}"; do
    [ -L "$HOME/.local/bin/$f" ] && printf '  %s\n' "$HOME/.local/bin/$f"
done
