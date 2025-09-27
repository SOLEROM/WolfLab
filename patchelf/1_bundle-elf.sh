#!/usr/bin/env bash
# bundle-elf.sh — Bundle a dynamic ELF and its shared libs into a self-contained dir.
# Usage:
#   bundle-elf.sh /path/to/elf  /path/to/outdir
#   bundle-elf.sh /path/to/elf  /path/to/outdir  --sysroot /path/to/sysroot   # for cross/foreign ELF
#
# Requires: bash, patchelf, readelf, ldd, coreutils, find

set -euo pipefail

if (( $# < 2 )); then
  echo "Usage: $0 <ELF> <OUTDIR> [--sysroot <SYSROOT>]" >&2
  exit 1
fi

ELF="$(readlink -f "$1")"
OUTDIR="$(readlink -m "$2")"
SYSROOT=""
if (( $# >= 4 )) && [[ "${3:-}" == "--sysroot" ]]; then
  SYSROOT="$(readlink -f "$4")"
fi

mkdir -p "$OUTDIR/lib"
install -m 0755 -D "$ELF" "$OUTDIR/$(basename "$ELF")"
ELF_BASENAME="$(basename "$ELF")"
ELF_OUT="$OUTDIR/$ELF_BASENAME"

die() { echo "ERROR: $*" >&2; exit 1; }

copy_with_symlinks() {
  local src="$1" dst_dir="$2"
  [[ -e "$src" ]] || die "Missing: $src"
  local real; real="$(readlink -f "$src")"
  install -m 0755 -D "$real" "$dst_dir/$(basename "$real")"
  # replicate symlink names that point to the real filename we just copied
  local cur="$src"
  while [[ -L "$cur" ]]; do
    ln -sf "$(basename "$real")" "$dst_dir/$(basename "$cur")"
    cur="$(dirname "$cur")/$(readlink "$cur")"
  done
}

interp=""          # e.g., /lib64/ld-linux-x86-64.so.2  OR /lib/ld-musl-...so.1
interp_basename=""
needed_paths=()

if [[ -z "$SYSROOT" ]]; then
  # Native mode
  interp="$(patchelf --print-interpreter "$ELF" 2>/dev/null || true)"
  if [[ -z "$interp" ]]; then
    interp="$(ldd "$ELF" | awk '/ld-linux|ld-musl|ld-uClibc/ {print $(NF)}' || true)"
  fi
  [[ -n "$interp" ]] || die "Could not detect program interpreter (is this static?)"

  while IFS= read -r line; do
    if [[ "$line" =~ "=> not found" ]]; then
      die "Unresolved dependency: $line"
    elif [[ "$line" =~ "=>" ]]; then
      p=$(awk '{print $3}' <<<"$line")
      [[ "$p" == /* ]] && needed_paths+=("$p")
    else
      p=$(awk '{print $1}' <<<"$line")
      [[ "$p" == /* ]] && needed_paths+=("$p")
    fi
  done < <(ldd "$ELF")
else
  # Cross/foreign mode
  interp="$(readelf -l "$ELF" | awk -F': ' '/Requesting program interpreter/ {print $2}')"
  [[ -n "$interp" ]] || die "Could not find program interpreter in $ELF"
  mapfile -t sonames < <(readelf -d "$ELF" | awk -F"[][]" '/NEEDED/ {print $2}')
  for so in "${sonames[@]}"; do
    found="$(find "$SYSROOT" -type f -name "$so" | head -n1 || true)"
    [[ -n "$found" ]] || die "In sysroot, cannot resolve $so"
    needed_paths+=("$found")
  done
fi

# Copy the interpreter and remember a friendly name we can call it with in run.sh
src_interp="$interp"
[[ -n "$SYSROOT" ]] && src_interp="$SYSROOT$interp"
[[ -e "$src_interp" ]] || die "Interpreter not found: $src_interp"
copy_with_symlinks "$src_interp" "$OUTDIR/lib"
# Prefer the common link name (basename of interp path as found in ELF)
interp_basename="$(basename "$interp")"
[[ -e "$OUTDIR/lib/$interp_basename" ]] || interp_basename="$(basename "$(readlink -f "$src_interp")")"

# Copy needed libraries
for lib in "${needed_paths[@]}"; do
  [[ -e "$lib" ]] || die "Missing lib path: $lib"
  copy_with_symlinks "$lib" "$OUTDIR/lib"
done

# NOTE: Do NOT change the ELF interpreter to $ORIGIN — the kernel won't expand it.
# We also don't strictly need to change RPATH if we run via the loader, but it doesn't hurt.
patchelf --force-rpath --set-rpath '$ORIGIN/lib' "$ELF_OUT" || true

# Create launcher that *execs our loader* with our lib dir
cat > "$OUTDIR/run.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail
HERE="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$HERE/lib/$interp_basename" --library-path "\$HERE/lib" "\$HERE/$ELF_BASENAME" "\$@"
SH
chmod +x "$OUTDIR/run.sh"

echo "Bundled -> $OUTDIR"
echo "Run: $OUTDIR/run.sh [args...]"
