# Ngôn ngữ myapp.legendsense

Chọn **Core → Language**: `English`, `中文` (Trung Quốc giản thể), `Tiếng Việt`.
Lựa chọn dùng chỉ số 0/1/2 và được lưu vào cấu hình menu hiện có. Đổi ngôn ngữ
không đổi phím nóng, giá trị tùy chọn, mã cấu hình hoặc tên script/tướng.
Giữ thư mục `Resource/fonts` hiện có: các font Noto Sans SC dùng để hiển thị
tiếng Trung, còn bộ glyph tiếng Việt đã được bổ sung vào font menu thường/đậm.

## Bộ dữ liệu

- `en-US.json`: khóa và nội dung tiếng Anh gốc.
- `zh-CN.json`: bản dịch tiếng Trung giản thể.
- `vi-VN.json`: bản dịch tiếng Việt.

File dùng UTF-8, cấu trúc là một object JSON phẳng: `"English source": "Bản dịch"`.
Giữ nguyên khóa bên trái và mọi tham số `%s`, `%d`, `{name}`, dấu xuống dòng;
chỉ sửa nội dung bên phải. Tên tướng, tên script, Q/W/E/R và phím bấm có thể giữ
nguyên. Không sửa hash/ID của game để thêm bản dịch.

## Cách nạp

DLL đã nhúng sẵn cả ba bộ dữ liệu. Khi khởi tạo menu, DLL đọc các file ghi đè tại:

`<thư mục gốc của loader>\Resource\Localization\myapp.legendsense\`

Thư mục gốc này lấy từ `Metadata::GetPath()` của loader, không nhất thiết là thư
mục chứa DLL. Trong workspace hiện tại, đây chính là thư mục chứa file README này.
Thay bản dịch rồi nạp lại DLL để đọc dữ liệu mới. Không đọc file liên tục trong
tick hoặc draw. File thiếu, JSON hỏng hoặc giá trị không phải chuỗi không làm
mất bản dịch tích hợp. Khóa chưa có bản dịch dùng tiếng Anh gốc; do đó script Lua
bên ngoài chưa có trong bộ từ điển vẫn có thể hiện tiếng Anh.

## Cập nhật và build

Từ thư mục gốc repository:

```powershell
# Sau khi sửa các bộ JSON, kiểm tra và tạo lại dữ liệu nhúng:
.\tools\localization\generate.ps1
.\tools\localization\generate.ps1 -Verify
.\tools\build.ps1 legendsense Fast
```

Build tự tạo lại header khi các bộ JSON thay đổi và chép ba file ra
`build\myapp.legendsense\release\Resource\Localization\myapp.legendsense\`.
Header đã sinh được giữ trong source để build không phải sinh lại khi dữ liệu
không thay đổi. Nếu cần sinh lại, máy build cần Node.js; công cụ cũng nhận runtime
Node được cài cùng môi trường Codex hiện tại.

`tools/localization/inventory.json` ghi nguồn của các chuỗi UI tĩnh; `coverage.json`
ghi thống kê từng ngôn ngữ sau lần kiểm tra. Inventory không bao gồm mọi chuỗi
động do game hoặc script Lua bên ngoài tự tạo. Khi bổ sung tính năng mới, chạy
`node tools/localization/catalogs.mjs --inventory` để cập nhật danh sách, rồi bổ
sung cả ba bộ. Lệnh inventory tạo lại English/Chinese từ source và các bản ghi đè
được rà soát trong `tools/localization`; không dùng lệnh này để lưu một chỉnh sửa
runtime tạm thời.

## Script Lua

`UI.GetLanguage()` giữ hợp đồng cũ: `1` cho tiếng Trung, `0` cho trường hợp khác,
để script cũ không tự chuyển sang tiếng Trung khi chọn tiếng Việt. Script mới dùng
`UI.GetLocale()` để nhận chính xác `en-US`, `zh-CN` hoặc `vi-VN`. Các nhãn tiếng Anh
do script đăng ký vào menu vẫn đi qua bộ dịch tiếng Việt khi có khóa tương ứng.
Với script tự chọn bản dịch ngay lúc load, hãy unload/load lại script sau khi đổi
ngôn ngữ để phần văn bản do chính script tạo cũng được khởi tạo lại.
