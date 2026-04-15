#!/usr/bin/env bash
# Install xkb-switch: prefer apt when the package exists; otherwise build from source to /usr/local.

ensure_xkb_switch() {
  if command -v xkb-switch >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi

  local runner=()
  if [ "$(id -u)" -eq 0 ]; then
    runner=()
  elif command -v sudo >/dev/null 2>&1; then
    runner=(sudo)
  else
    return 1
  fi

  "${runner[@]}" apt-get update -qq

  if apt-cache show xkb-switch >/dev/null 2>&1; then
    if "${runner[@]}" apt-get install -y xkb-switch; then
      return 0
    fi
  fi

  local build_deps=(cmake build-essential g++ git libx11-dev libxkbfile-dev pkg-config)
  if ! "${runner[@]}" apt-get install -y --no-install-recommends "${build_deps[@]}"; then
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap 'rm -rf "$tmp"' RETURN

  if ! git clone --depth 1 https://github.com/sergei-mironov/xkb-switch.git "$tmp/xkb-switch"; then
    return 1
  fi

  # Prefer GCC: some images symlink c++ to Clang without a working libstdc++ link for the linker.
  export CC="${CC:-gcc}"
  export CXX="${CXX:-g++}"
  cmake -S "$tmp/xkb-switch" -B "$tmp/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
  cmake --build "$tmp/build" -j"$(nproc 2>/dev/null || echo 4)"

  if [ "$(id -u)" -eq 0 ]; then
    cmake --install "$tmp/build"
    ldconfig 2>/dev/null || true
  else
    sudo cmake --install "$tmp/build"
    sudo ldconfig 2>/dev/null || true
  fi

  command -v xkb-switch >/dev/null 2>&1
}
