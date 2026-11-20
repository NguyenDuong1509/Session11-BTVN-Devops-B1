# BÁO CÁO KỸ THUẬT: CẤU HÌNH NGINX REVERSE PROXY VÀ XỬ LÝ LỖI (SESSION 11 - BÀI 1)

## 1. Khái niệm Reverse Proxy & Kiến trúc mạng thực tế

### 1.1. Phân biệt Forward Proxy vs Reverse Proxy
- **Forward Proxy (Proxy xuôi):**
  - Đứng trước một nhóm người dùng (Clients) đi ra Internet.
  - Mục đích: Ẩn danh client, vượt tường lửa, lọc nội dung web của nhân viên văn phòng.
  - *Ví dụ:* Squid Proxy trong mạng doanh nghiệp.
- **Reverse Proxy (Proxy ngược):**
  - Đứng trước một hoặc nhiều máy chủ dịch vụ (Web/App Servers).
  - Khách hàng (Client) trên Internet chỉ nhìn thấy và giao tiếp duy nhất với Reverse Proxy.
  - *Mục đích:* Điều phối tải (Load Balancing), mã hóa SSL/TLS Termination, nén dữ liệu (Gzip), Cache nội dung tĩnh, và định tuyến cổng nội bộ.

---

## 2. Phân tích chi tiết chỉ thị `proxy_pass` và các Header đi kèm

### 2.1. Cú pháp `proxy_pass`
```nginx
location / {
    proxy_pass http://localhost:3000;
}
```
- Khi Nginx nhận request có URI khớp với `/`, nó chuyển tiếp request đó sang máy chủ backend được chỉ định sau từ khóa `proxy_pass`.
- Trong bài toán này, ứng dụng React chạy trên cùng máy chủ VPS tại cổng 3000 (`http://localhost:3000`).

### 2.2. Tầm quan trọng của các Header chuyển tiếp
Khi đứng sau một Reverse Proxy, ứng dụng backend có nguy cơ bị "mất" các thông tin gốc của client vì mọi request gửi tới backend đều mang IP của chính Nginx (`127.0.0.1`). Để khắc phục, Nginx cần thiết lập các header:
- `proxy_set_header Host $host;`: Giúp backend biết tên miền thật mà client đang gọi.
- `proxy_set_header X-Real-IP $remote_addr;`: Chuyển tiếp địa chỉ Public IP thực của client vào header HTTP để backend ghi log hoặc kiểm tra bảo mật.
- `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`: Danh sách IP nếu request đi qua nhiều tầng proxy.
- `proxy_set_header X-Forwarded-Proto $scheme;`: Cho backend biết client dùng giao thức HTTP hay HTTPS.

---

## 3. Phân tích chuyên sâu câu hỏi bẫy: HTTP 502 Bad Gateway

### 3.1. Tại sao lại là 502 mà không phải 404 hay 504?
- **404 Not Found:** Xảy ra khi server backend vẫn hoạt động bình thường nhưng không tìm thấy tài nguyên (file hoặc URL route).
- **504 Gateway Timeout:** Xảy ra khi Nginx kết nối thành công tới port 3000, nhưng ứng dụng backend bị treo (hang) hoặc xử lý quá lâu khiến thời gian chờ vượt quá giới hạn timeout (`proxy_read_timeout`).
- **502 Bad Gateway:** Xảy ra khi Nginx đóng vai trò là Gateway nhưng **nhận phản hồi không hợp lệ hoặc không thể thiết lập kết nối TCP** tới upstream server (`localhost:3000`).

### 3.2. Tiến trình bắt tay khi port 3000 bị sập
1. Client gửi `GET / HTTP/1.1` tới Nginx ở cổng 80.
2. Nginx tạo socket và gửi gói tin `TCP SYN` tới `127.0.0.1:3000`.
3. Do tiến trình React đã bị sập (không có tiến trình nào lắng nghe cổng 3000), Kernel hệ điều hành phản hồi ngay lập tức gói tin `TCP RST, ACK` (Reset - Connection Refused).
4. Nginx ghi nhận lỗi trong file `/var/log/nginx/error.log`:
   `connect() failed (111: Connection refused) while connecting to upstream`
5. Nginx sinh mã trạng thái **HTTP 502 Bad Gateway** và gửi trang thông báo lỗi chuẩn về cho Client.

---

## 4. Hướng dẫn nộp bài lên hệ thống Portal

1. **Link GitHub repository nộp bài:**
   ```text
   https://github.com/NguyenDuong1509/Session11-BTVN-Devops-B1
   ```
2. **File cấu hình và giải thích:**
   - File cấu hình [nginx/sites-available/default](file:///nginx/sites-available/default).
   - Giải thích chỉ thị `proxy_pass` và mã lỗi `502 Bad Gateway` chi tiết trong README.md.
3. **Ảnh minh chứng đính kèm:**
   - `homework/session_11/exercise_01/nginx_reverse_proxy_config.png`
   - `homework/session_11/exercise_01/nginx_proxy_success_200.png`
   - `homework/session_11/exercise_01/nginx_502_bad_gateway_proof.png`
