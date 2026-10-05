# Báo Cáo Phân Tích Đánh Đổi Hiệu Năng (Read vs Write) - Dự Án SmartFactory

## 1. Tóm Tắt Tình Trạng Ban Đầu
Màn hình Dashboard của SmartFactory truy vấn lịch sử nhiệt độ cực nhanh nhờ `Covering Index` (`idx_fat_covering`) ôm trọn 5 cột. Tuy nhiên, việc nhét cả 3 cột dữ liệu liên tục biến động (`temperature`, `humidity`, `status`) vào Index gây hậu quả nghiêm trọng:
- **Nghẽn luồng Ghi (Write Penalty):** 10,000 cảm biến gửi dữ liệu mỗi giây làm cây B-Tree liên tục phải thực hiện Rebalance và Page Split, làm `INSERT` bị trễ/rớt kết nối.
- **Phình to Ổ cứng:** Kích thước Index vượt cả dung lượng dữ liệu gốc (Data Length), đẩy chi phí lưu trữ AWS SSD tăng gấp 4 lần.

## 2. Giải Pháp "Lean Index" (Chỉ Mục Tinh Gọn)
Tiến hành gỡ bỏ `idx_fat_covering` và thay thế bằng `idx_lean_search` chỉ chứa 2 cột lọc: `(sensor_id, recorded_at)`.

### Bảng So Sánh Đánh Đổi (Trade-off Matrix)

| Tiêu chí | Cấu hình cũ (Fat Index) | Cấu hình mới (Lean Index) | Đánh giá mức độ ảnh hưởng |
| :--- | :--- | :--- | :--- |
| **Thao tác SELECT (Dashboard)** | ~1ms (Không chạm vào Disk Table) | ~3ms (Thêm lượt Bookmark Lookup) | Trải nghiệm người dùng hầu như không đổi. |
| **Thao tác INSERT (Cảm biến)** | Rất chậm (Gây Timeout, ngốn I/O) | Nhanh hơn **3 - 5 lần** | Giải quyết triệt để lỗi nghẽn Data Pipeline. |
| **Kích thước Index (Storage)** | ~100% dung lượng bảng | **Giảm 60% - 70%** | Giảm thiểu đáng kể chi phí Cloud Storage. |
| **Tải bộ nhớ RAM (Buffer Pool)** | Nạp tràn các trang Index ngốn RAM | Nạp vừa đủ trang Index, nhường RAM cho Data | Tăng tỷ lệ Cache Hit cho toàn CSDL. |

## 3. Kết Luận
Sự đánh đổi mất đi một vài phần nghìn giây của lệnh `SELECT` để đổi lấy sự ổn định tuyệt đối của luồng `INSERT` và tiết kiệm hàng ngàn USD chi phí Cloud là một quyết định kiến trúc hoàn toàn đúng đắn cho các hệ thống thời gian thực (Real-time IoT).