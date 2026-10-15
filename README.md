# Gõ tiếng Việt không gạch chân trên Ubuntu 26.04 (GNOME Wayland)

Ghi chú để làm lại cấu hình gõ tiếng Việt bằng IBus + Bamboo mà không bị gạch chân (pre-edit) trong Terminal và trình duyệt. Ghi lại từ một máy cụ thể, nên các phiên bản bên dưới là phiên bản đã dùng.

## Môi trường đã dùng

| Thành phần | Phiên bản |
|---|---|
| Hệ điều hành | Ubuntu 26.04, GNOME Wayland |
| IBus | 1.5.34 |
| ibus-bamboo | 0.8.5-0~202605181527~ubuntu26.04.1 |
| Mutter | 50.1-0ubuntu2.4, vá thành `+local1` |
| Biến môi trường | `XMODIFIERS=@im=ibus`, `QT_IM_MODULE=ibus` |

## Vì sao có gạch chân

Chế độ mặc định của Bamboo là **Pre-edit**. Chữ đang gõ được gửi tới ứng dụng dưới dạng "chữ chưa chốt", nên ứng dụng vẽ gạch chân. Các chế độ khác của Bamboo gõ thẳng chữ vào ứng dụng bằng cách xóa rồi chèn lại, nên không có gạch chân.

Chế độ Bamboo (trường `DefaultInputMode` trong `~/.config/ibus-bamboo/ibus-bamboo.config.json`):

| Giá trị | Chế độ |
|---|---|
| 1 | Mặc định (Pre-edit), có gạch chân |
| 2 | Surrounding Text |
| **3** | **ForwardKeyEvent I, đang dùng** |
| 4 | ForwardKeyEvent II |
| 5 | Forward as commit |
| 6 | XTestFakeKeyEvent (chỉ X11) |
| 7 | Thêm vào danh sách loại trừ |

## Cách làm lại

### Bước 1. Đặt Bamboo sang chế độ 3

```sh
./scripts/apply-bamboo-config.sh
```

Script này sao lưu file cấu hình cũ, chép `config/ibus-bamboo.config.json` (`{"DefaultInputMode":3}`), đặt nguồn nhập GNOME về `us` và `Bamboo`, rồi nạp lại IBus. Bạn cũng có thể làm tay: sửa file cấu hình, chạy `ibus restart`, rồi `ibus engine Bamboo`.

> Script đặt lại toàn bộ danh sách nguồn nhập. Nếu bạn còn nguồn nhập khác (Unikey, bàn phím Nhật…), sửa dòng `gsettings set` trước khi chạy.

### Bước 2. Vá Mutter

Trên Ubuntu 26.04 với Mutter 50.1, phím Backspace do bộ gõ gửi qua IBus `ForwardKeyEvent` bị bỏ qua. Nguyên nhân là Mutter kiểm tra nhầm thiết bị nguồn của sự kiện. Vì vậy chế độ 3 chưa dùng được nếu chưa vá.

- Bản vá: `patches/mutter-clutter-event-ime-flag.diff`. Chỉ sửa một điều kiện trong `clutter/clutter/clutter-event.c`.
- Đây là bản sửa của upstream, có trong Mutter 50.4 (commit `570de65dd05e1b362fdef90dcb811c22acd8a8e2`). Từ bản đó trở đi không cần tự vá.
- Nếu bản `mutter` của Ubuntu đã gồm bản sửa này thì bỏ qua bước 2.

Dựng gói đã vá trong container (không đụng vào hệ thống đang chạy):

```sh
./scripts/build-mutter.sh ./out
```

> Script này mình viết lại từ ghi chú của lần dựng trước, **chưa chạy lại để kiểm chứng**. Lần dựng gốc dùng container Ubuntu 26.04 và `DEB_BUILD_OPTIONS=nocheck`. Nếu `apt-get build-dep` hoặc `dch` lỗi, sửa tay rồi ghi lại vào đây.

Cài hai gói `libmutter-18-0` và `gir1.2-mutter-18` đã dựng:

```sh
sudo apt-get install --no-remove ./out/libmutter-18-0_*+local1_amd64.deb ./out/gir1.2-mutter-18_*+local1_amd64.deb
```

**Đăng xuất rồi đăng nhập lại** để GNOME nạp thư viện mới.

Quay lui: cài lại hai gói gốc bằng `sudo apt-get install --no-remove --allow-downgrades libmutter-18-0=<phiên bản gốc> gir1.2-mutter-18=<phiên bản gốc>` (xem `apt-cache policy libmutter-18-0`). Nếu giao diện không khởi động, vào TTY bằng Ctrl+Alt+F3, chạy lệnh quay lui, rồi khởi động lại.

### Bước 3 (tùy chọn). Vá nhịp Backspace của Bamboo

`patches/bamboo-backspace-timing.diff` tăng khoảng chờ giữa các phím Backspace trong chế độ ForwardKeyEvent I (thêm 12 ms sau mỗi Backspace và đổi 30 thành 45 ms ở khoảng chờ cuối).

**Chưa kiểm chứng hiệu quả.** Bản này dựng từ tag `v0.8.5` của ibus-bamboo và chỉ qua `go test -mod=vendor ./...`. Máy hiện chạy bản Bamboo gốc, không phải bản vá. Chỉ thử nếu bạn gặp lỗi mất chữ hoặc Backspace chạy sai thứ tự.

## Kiểm tra

1. `ibus engine` in ra `Bamboo`.
2. Gõ `Chaof`, `Vieetj` trong Terminal và trình duyệt, xem có gạch chân hoặc nhấp nháy không.
3. Kiểm tra `cat ~/.config/ibus-bamboo/ibus-bamboo.config.json` vẫn là `{"DefaultInputMode":3}`.

## Hay gặp

- **Mất bộ gõ sau khi IBus tắt:** danh sách nguồn nhập GNOME có thể bị reset về `us`. Chạy lại `scripts/apply-bamboo-config.sh`. Việc này đã xảy ra một lần mà không rõ nguyên nhân.
- **Gạch chân quay lại sau cập nhật hệ thống:** `apt upgrade` có thể thay `libmutter` bản vá bằng bản chính thức. Nếu bản chính thức chưa có bản sửa, dựng và cài lại bước 2.
- **Terminal (VTE) và một số ứng dụng:** chế độ dựa trên surrounding text (chế độ 2) không dùng được trong Ptyxis/VTE 0.84, vì VTE chưa hỗ trợ delete-surrounding. Chế độ 3 không phụ thuộc điều đó.

## Đã thử và không dùng

- **Bản Wayland POC** (fork Bamboo dùng chế độ 2, bỏ độ trễ quanh `DeleteSurroundingText`): vẫn lỗi `Chào` thành `chaào` và chạy kém trong Terminal, nên không đưa vào đây.
- **Fcitx5 + Unikey / bộ gõ tự viết:** thử nhưng không dùng.

## Giấy phép

- Ghi chú và script trong repo này: MIT.
- Các bản vá theo giấy phép của dự án gốc: Mutter (GPL-2.0-or-later), ibus-bamboo (GPL-3.0).
