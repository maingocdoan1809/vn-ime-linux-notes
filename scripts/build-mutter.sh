#!/bin/sh
# Dựng lại libmutter đã vá, trong container Ubuntu 26.04 (không đụng vào hệ thống đang chạy).
# Cần: docker (hoặc podman), thư mục hiện tại ghi được.
# Đổi MUTTER_VERSION nếu Ubuntu đã đẩy bản mới hơn; xem apt-cache policy mutter.
set -eu
dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
out="${1:-$PWD/out}"
mkdir -p "$out"
docker run --rm -v "$dir/patches:/patches:ro" -v "$out:/out" ubuntu:26.04 bash -ec '
  sed -i "s/^Types: deb$/Types: deb deb-src/" /etc/apt/sources.list.d/ubuntu.sources
  apt-get update
  apt-get install -y dpkg-dev devscripts
  apt-get build-dep -y mutter
  mkdir /build && cd /build
  apt-get source mutter
  cd mutter-*/
  patch -p1 < /patches/mutter-clutter-event-ime-flag.diff
  dch --local +local "Allow IBus ForwardKeyEvent without a source device (upstream mutter 50.4 fix)"
  DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -b
  cp /build/*.deb /out/
'
echo "Gói đã dựng nằm ở: $out"
