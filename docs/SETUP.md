# ⚙️ دليل الإعداد — من الصفر إلى APK

## المرحلة 0 — المتطلبات

| الحاجة | النسخة |
|---|---|
| Flutter | 3.35.3 (Dart 3.9.2) |
| Java | 17 |
| حساب Supabase | مجاني |
| حساب Codemagic | مجاني (500 دقيقة/شهر) |
| حساب GitHub | موجود |

---

## المرحلة 1 — Supabase (10 دقائق)

### 1.1 إنشاء المشروع
1. <https://supabase.com> → **New project**
2. الاسم: `latchi-store-dz`
3. كلمة سر قاعدة البيانات: احفظها
4. Region: أقرب واحد (Frankfurt للجزائر)

### 1.2 تشغيل السكيما
1. **SQL Editor** → **New query**
2. افتح `supabase/01_schema.sql` والصق **كلشي**
3. **Run** (Ctrl+Enter)
4. المتوقع: `Success. No rows returned`

> ⚠️ إذا ظهر خطأ `already exists` ⇒ السكيما تشغّلت من قبل. عادي، الـ`if not exists` يغطيها.

### 1.3 نسخ المفاتيح
**Settings → API**

| الحقل فـSupabase | اسم المتغير |
|---|---|
| Project URL | `SUPABASE_URL` |
| `anon` `public` | `SUPABASE_ANON_KEY` |

> ⚠️ **never** استعمل `service_role` فـالتطبيق — يتجاوز كل RLS.

### 1.4 تأكيد أن الـBuckets تصنعت
**Storage** → لازم تشوف:
- `product-images` (public)
- `store-assets` (public)
- `avatars` (public)

---

## المرحلة 2 — حساب التاجر

### 2.1 سجّل من التطبيق
افتح التطبيق → **أنا تاجر** → **سجّل** → إيميل + كلمة سر (6+).

### 2.2 رقّيه لـmerchant
```sql
-- بدّل الإيميل
update public.profiles
   set role = 'merchant'
 where email = 'you@example.com';
```

### 2.3 أنشئ المتجر
```sql
insert into public.stores (owner_id, name, slug, phone, wilaya_code, commune_name)
select id, 'متجري', 'my-store', '0555000000', '16', 'الجزائر الوسطى'
from public.profiles
where email = 'you@example.com';
```

### 2.4 أسعار التوصيل (مهم!)
```sql
-- مثال: 16 الجزائر · 200 دج للمنزل · 150 للمكتب
insert into public.store_delivery_rates
  (store_id, wilaya_code, wilaya_name, home_price, stopdesk_price)
select s.id, x.code, x.name, x.home, x.desk
from public.stores s,
(values
  ('16','الجزائر',400,250),
  ('31','وهران',600,400),
  ('25','قسنطينة',600,400),
  ('09','البليدة',450,300),
  ('06','بجاية',650,450)
) as x(code,name,home,desk)
where s.slug = 'my-store';
```
> ما تحطّش سعر ⇒ التوصيل يولّي **0 دج** (مجاني).

---

## المرحلة 3 — البناء على Codemagic

### 3.1 اربط المستودع
1. <https://codemagic.io> → **Add application**
2. اختار **GitHub** → `latchidz/LATCHI-STORE-DZ`
3. اختار **Flutter App**

### 3.2 المتغيرات
**Settings → Environment variables** → أضف:

| الاسم | القيمة | Secure? |
|---|---|---|
| `SUPABASE_URL` | `https://xxx.supabase.co` | ✅ |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` | ✅ |
| `CM_EMAIL` | إيميلك | ❌ |

### 3.3 مفتاح التوقيع (Android)
باش ترفع لـGoogle Play، تحتاج keystore:

```bash
keytool -genkey -v -keystore latchi-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS
```

**Codemagic → Code signing identities → Android keystores → Upload**
- الملف: `latchi-upload.jks`
- الـalias: `upload`
- كلمة السر: (اللي حطيتها)

الاسم فـ`codemagic.yaml` = `latchi_keystore` (لازم يطابق).

### 3.4 شغّل البناء
`Start new build` → `android-release` → **Start**

المدة: **8–15 دقيقة** (أول مرة أكثر)

### 3.5 التحميل
**Artifacts:**
- `app-release.apk` ← للاختبار المباشر
- `app-release.aab` ← لـGoogle Play

---

## المرحلة 4 — التوزيع

### APK مباشر
ابعث `app-release.apk` للمختبرين (يفعّلوا "تثبيت من مصادر غير معروفة").

### Google Play
1. <https://play.google.com/console> → **Create app**
2. Package: `dz.latchi.latchi_store_dz`
3. **Internal testing** → ارفع `.aab`
4. عمّر: وصف، لقطات، سياسة الخصوصية، تصنيف المحتوى

---

## 🔧 حل المشاكل

| المشكلة | الحل |
|---|---|
| `Supabase ماشي مضبوط` | ما مرّرش `--dart-define`. تأكد من الأسماء بالضبط |
| الصور ما تظهرش | Bucket ماشي public، ولا RLS على `storage.objects` ناقص |
| `NOT_OWNER` | الـ`store.owner_id` ماشي نفس `auth.uid()` |
| السكيما تفشل | شغّلها بالترتيب، ما تقطعش ولا سطر |
| `flutter analyze` يفشل فـCI | شغّل `flutter analyze` محلياً قبل الـpush |
| Gradle يعلق | زيد الـcache فـcodemagic.yaml (موجود) |

---

## 🔐 ملاحظات أمان

1. **`anon key` آمن للعرض** — الحماية من RLS ماشي من إخفاء المفتاح.
2. **`service_role`** — عمرو ما يدخل التطبيق.
3. **`place_order`** هي الطريقة الوحيدة لإنشاء طلب — تتحقق من المخزون والأسعار server-side.
4. **الزبون ما يقدرش يقرا** حتى طلب بلا تسجيل.
5. **السلات المحلية** (`cart_items`) RLS مفتوحة — إذا تحب خصوصية أكثر، استعمل `shared_preferences` بدل الجدول.
