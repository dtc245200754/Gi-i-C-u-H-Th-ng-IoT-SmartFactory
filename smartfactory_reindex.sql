-- ============================================================================
-- DỰ ÁN SMARTFACTORY - CÂN BẰNG HIỆU NĂNG VÀ TỐI ƯU HÓA INDEX HỆ THỐNG IOT
-- Vai trò: Database Optimization Expert
-- ============================================================================

USE smartfactory_db;

-- 1. KIỂM TRA TÌNH TRẠNG LƯU TRỮ VÀ INDEX BAN ĐẦU
SHOW TABLE STATUS LIKE 'SensorLogs';
SHOW INDEX FROM SensorLogs;

-- Phân tích câu truy vấn Dashboard khi còn "Fat Index":
-- (Kết quả EXPLAIN ở phiên bản cũ sẽ có Extra = 'Using index')
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';


-- 2. THỰC HIỆN "PHẪU THUẬT" TỐI ƯU INDEX

-- Bước 2.1: Loại bỏ "Fat Index" dư thừa gây nghẽn luồng GHI (Write Bottleneck)
ALTER TABLE SensorLogs DROP INDEX idx_fat_covering;

-- Bước 2.2: Tạo Lean Index (Chỉ mục tinh gọn) chỉ chứa các cột phục vụ Lọc (WHERE) và Sắp xếp (ORDER BY)
CREATE INDEX idx_lean_search ON SensorLogs(sensor_id, recorded_at);


-- 3. ĐỐI CHIẾU VÀ XÁC MINH HIỆU NĂNG SAU KHI CHUYỂN ĐỔI

-- Kiểm tra lại dung lượng Index_length đã giảm mạnh
SHOW TABLE STATUS LIKE 'SensorLogs';

-- Kiểm tra lại kế hoạch thực thi (Execution Plan) của câu truy vấn Dashboard
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';

/*
  NHẬN XÉT KẾT QUẢ EXPLAIN SAU KHI TỐI ƯU:
  - Cột `key`: Nhận diện đúng Index tinh gọn `idx_lean_search`.
  - Cột `type`: Giữ nguyên dạng `range` hoặc `ref` (Tốc độ tìm kiếm vẫn siêu tốc).
  - Cột `Extra`: KHÔNG còn chữ "Using index". MySQL sẽ dùng `idx_lean_search` để lọc cực nhanh ra các bản ghi thỏa mãn, 
    sau đó thực hiện "Bookmark Lookup" về Clustered Index (Bảng gốc) để lấy `temperature`, `humidity`, `status`.
*/