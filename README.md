# QuickBite E-Commerce Platform
## Session 11 - Bài 1: Vận dụng cơ bản - "Cấu hình Nginx Reverse Proxy Cơ Bản"

---

## 📌 1. Bối cảnh nghiệp vụ & Mục tiêu
- **Vấn đề thực tế:** Ứng dụng E-commerce Frontend (React) đang chạy ở cổng nội bộ `3000` trên VPS. Nếu bắt người dùng phải gõ `http://domain.com:3000` thì trải nghiệm người dùng rất kém, thiếu chuyên nghiệp và buộc phải mở thêm cổng 3000 ra Internet (tăng bề mặt tấn công).
- **Giải pháp:** Sử dụng **Nginx làm Reverse Proxy** lắng nghe tại cổng chuẩn **HTTP 80** (`http://domain.com`), sau đó chuyển tiếp ngầm toàn bộ request tới ứng dụng React chạy tại `localhost:3000`.

---

## ⚙️ 2. File cấu hình Nginx chuẩn xác (`/etc/nginx/sites-available/default`)

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        # Chỉ thị cốt lõi: Chuyển tiếp request sang ứng dụng React chạy tại port 3000
        proxy_pass http://localhost:3000;

        # Cấu hình header chuyển tiếp thông tin client
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## ❓ 3. Giải đáp 2 câu hỏi trọng tâm của đề bài

### 3.1. Giải thích ý nghĩa của chỉ thị `proxy_pass`
* **Ý nghĩa cốt lõi:** `proxy_pass http://localhost:3000;` là chỉ thị chỉ định địa chỉ của **Upstream Server** (máy chủ backend nội bộ) mà Nginx sẽ chuyển tiếp các request của client tới.
* **Cơ chế hoạt động:**
  1. Client gửi request tới Nginx tại `http://domain.com/` (Port 80).
  2. Nginx nhận request, phân tích khối `location /` và thiết lập kết nối socket nội bộ mới tới `http://localhost:3000`.
  3. Ứng dụng React xử lý và trả kết quả về cho Nginx.
  4. Nginx đóng gói và chuyển tiếp kết quả đó ngược lại cho Client.
* **Lợi ích:** Ẩn giấu hoàn toàn kiến trúc hạ tầng và số port backend phía sau, tăng cường bảo mật và mang lại URL chuẩn đẹp cho người dùng.

---

### 3.2. Bẫy: Nếu ứng dụng React ở port 3000 bị sập, Nginx sẽ trả về lỗi HTTP Code nào?

> [!IMPORTANT]
> **Câu trả lời chính xác:** Nginx sẽ trả về mã lỗi **`HTTP 502 Bad Gateway`**.

#### Phân tích cơ chế kỹ thuật chi tiết:
* Nginx đóng vai trò là một **Gateway / Reverse Proxy** kết nối giữa Client và Upstream Server.
* Khi ứng dụng React ở cổng 3000 bị sập (tiến trình dừng, process exited, port 3000 không có service nào lắng nghe):
  - Khi Nginx cố gắng bắt tay TCP (TCP 3-way handshake) tới `localhost:3000`, hệ điều hành sẽ lập tức gửi trả gói tin **TCP RST** (`Connection Refused`).
  - Nginx nhận được tín hiệu từ chối kết nối hoặc phản hồi không hợp lệ từ upstream server.
  - Theo đặc tả chuẩn RFC của giao thức HTTP, khi Proxy không thể nhận được phản hồi hợp lệ từ server cấp trên, nó sẽ sinh ra mã trạng thái **`502 Bad Gateway`** gửi về cho trình duyệt.
* **Phân biệt với `504 Gateway Timeout`:** 
  - `504 Gateway Timeout` chỉ xảy ra khi backend **vẫn sống** nhưng phản hồi quá chậm vượt quá ngưỡng thời gian chờ (`proxy_read_timeout`).
  - Khi backend **chết hẳn / sập hoàn toàn**, phản hồi luôn là **`502 Bad Gateway`** ngay lập tức.

---

## 📸 4. Hình ảnh minh chứng nộp bài

Các ảnh minh chứng được lưu trữ tại thư mục [homework/session_11/exercise_01](file:///C:/Users/admin/.gemini/antigravity/scratch/QuickBite-Session11-B1/homework/session_11/exercise_01/):
1. 🖼️ **Ảnh chụp file cấu hình Nginx Reverse Proxy:**
   * [nginx_reverse_proxy_config.png](file:///homework/session_11/exercise_01/nginx_reverse_proxy_config.png): Thể hiện file cấu hình chuẩn với `proxy_pass http://localhost:3000;`, kiểm tra cú pháp `nginx -t` và reload service.
2. 🖼️ **Ảnh truy cập thành công qua cổng 80 (HTTP 200 OK):**
   * [nginx_proxy_success_200.png](file:///homework/session_11/exercise_01/nginx_proxy_success_200.png): Truy cập `http://54.254.198.85` (không cần gõ `:3000`) hiển thị trang React E-Commerce Storefront.
3. 🖼️ **Ảnh minh chứng bẫy lỗi HTTP 502 Bad Gateway khi React sập:**
   * [nginx_502_bad_gateway_proof.png](file:///homework/session_11/exercise_01/nginx_502_bad_gateway_proof.png): Dừng container React và gửi request qua cổng 80, Nginx trả về `HTTP/1.1 502 Bad Gateway`.

---

## 📁 5. Cấu trúc thư mục Repository
```text
.
├── .gitignore
├── README.md                      # Hướng dẫn chi tiết bài tập & giải đáp câu hỏi
├── EXPLANATION.md                 # Báo cáo chuyên sâu về Reverse Proxy và HTTP 502
├── commands.txt                   # Danh sách các câu lệnh Linux đã thực thi
├── docker-compose.yml             # Triển khai Nginx Proxy & React Demo 1-click
├── app/
│   └── index.html                 # Ứng dụng React Storefront demo port 3000
├── nginx/
│   └── sites-available/
│       └── default                # File cấu hình Nginx Reverse Proxy hoàn chỉnh
└── homework/
    └── session_11/
        └── exercise_01/
            ├── nginx_reverse_proxy_config.png    # Ảnh cấu hình Nginx
            ├── nginx_proxy_success_200.png       # Ảnh truy cập HTTP 200 OK
            └── nginx_502_bad_gateway_proof.png   # Ảnh lỗi 502 Bad Gateway
```
