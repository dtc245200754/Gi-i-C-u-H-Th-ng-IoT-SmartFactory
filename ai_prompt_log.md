# Nhật Ký Tương Tác AI (AI Prompt Log) - Dự Án SmartFactory

### Session 1: Tìm hiểu về Covering Index & Clustered/Secondary Index
- **Prompt:** "Trong MySQL InnoDB, Covering Index là gì? Tại sao khi câu lệnh EXPLAIN hiển thị 'Using index' trong cột Extra thì tốc độ SELECT lại đạt tối đa nhưng thao tác INSERT lại chịu ảnh hưởng tiêu cực?"
- **AI Response Summary:** AI giải thích cơ chế Index-Only Scan (không cần Lookup vào Clustered Index/Primary Key). Đồng thời chỉ rõ chi phí "Write Penalty": khi chèn bản ghi mới, mọi Secondary Index B-Tree đều phải ghi thêm Node, nếu Node đầy sẽ gây Page Split ngốn tài nguyên I/O đĩa.

### Session 2: Tính toán dung lượng lưu trữ bộ nhớ (Byte Calculation)
- **Prompt:** "Hãy tính toán dung lượng Kích thước Byte của 1 dòng Index B-Tree đối với `idx_fat_covering` (BIGINT + INT + DATETIME + DECIMAL(5,2) + DECIMAL(5,2) + VARCHAR(20)) so với `idx_lean_search` (INT + DATETIME + Primary Key BIGINT) trong MySQL InnoDB?"
- **AI Response Summary:** 
  - **Fat Index Key Size:** 8B (BIGINT) + 4B (INT) + 5B (DATETIME) + 3B (DECIMAL) + 3B (DECIMAL) + ~20-80B (VARCHAR) + 8B (PK Lookup) $\approx$ **51 - 109 Bytes / row**.
  - **Lean Index Key Size:** 4B (INT) + 5B (DATETIME) + 8B (PK Lookup) $\approx$ **17 Bytes / row**.
  - **Kết luận:** Lean Index tiết kiệm từ **65% - 80%** dung lượng bộ nhớ cho mỗi dòng index được lưu trữ.