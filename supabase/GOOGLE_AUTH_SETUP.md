# Google OAuth Setup cho aatodo

## Bước 1: Tạo Google OAuth App

1. **Truy cập**: https://console.cloud.google.com/apis/credentials
2. **Chọn project** hoặc tạo mới
3. **Màn hình đồng ý**: OAuth consent screen
   - User type: External
   - App name: aatodo
   - User support email: email của bạn
   - Developer contact: email của bạn
   - Lưu và tiếp tục

4. **Tạo OAuth 2.0 credentials**:
   - Click **Create Credentials** → **OAuth client ID**
   - Application type: Web application
   - Name: aatodo Supabase
   - Authorized redirect URIs:
     ```
     https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback
     ```
   - Click **Create**

5. **Lưu thông tin**:
   - Client ID: `xxxxxxxxxx.apps.googleusercontent.com`
   - Client Secret: `GOCSPX-xxxxxxxxxx`

## Bước 2: Cấu hình trong Supabase

1. Vào Supabase Dashboard → **Authentication** → **Providers**
2. Tìm **Google** → Click enable
3. Điền thông tin:
   - **Client ID**: [paste từ Google Console]
   - **Client Secret**: [paste từ Google Console]
   - **Redirect URL**: [điền URL callback của Supabase]
4. Click **Save**

## Bước 3: Test

1. Trong Supabase Dashboard → **Authentication** → **Users**
2. Click **"Add user"** → **"Invite user with magic link"**
3. Hoặc test với client SDK sau khi integrate

---

## Credentials cần lưu (KHÔNG commit vào git)

```
SUPABASE_URL=https://<PROJECT_REF>.supabase.co
SUPABASE_ANON_KEY=<anon_key_from_dashboard>
```

Cách lấy:
- Supabase Dashboard → **Project Settings** → **API**
- Copy URL và anon key
- Lưu vào Keychain hoặc file .env (đã exclude trong .gitignore)
