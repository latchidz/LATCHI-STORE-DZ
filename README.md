# 🛍️ LATCHI STORE DZ

تطبيق موبايل للتجارة الإلكترونية الجزائرية — **Flutter + Supabase** — الدفع عند الاستلام (COD).

**واجهتان فـcodebase واحد:** لوحة التاجر + متجر الزبون.

---

## 📱 لقطات

| الزبون | التاجر |
|---|---|
| متجر · بحث · سلة · Checkout COD بلا حساب | لوحة تحكم · طلبات لحظية · CRM · متابعات · بون توصيل |

---

## ⚡ البدء السريع (5 دقائق)

### 1. Supabase
```
1. أنشئ مشروع على https://supabase.com  (مجاني)
2. SQL Editor → New query → الصق كل محتوى supabase/01_schema.sql → Run
3. Settings → API → انسخ:
     Project URL       → SUPABASE_URL
     anon public key   → SUPABASE_ANON_KEY
```

### 2. شغّل التطبيق محلياً
```bash
flutter pub get

# شغّل مع مفاتيحك:
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```
> بلا مفاتيح ⇒ التطبيق يفتح في **وضع Demo** (بيانات فارغة، الطلب ينجح محلياً).

### 3. سوّي تاجر
```sql
-- فـSupabase SQL Editor، بدّل الإيميل:
update public.profiles set role = 'merchant' where email = 'you@example.com';

insert into public.stores (owner_id, name, slug, phone)
select id, 'متجري', 'my-store', '0555000000'
from public.profiles where email = 'you@example.com';
```

### 4. ارفع على Codemagic
```
Codemagic → Add application → GitHub → latchidz/LATCHI-STORE-DZ
Environment variables (Secure):
   SUPABASE_URL
   SUPABASE_ANON_KEY
```
الملف `codemagic.yaml` موجود — البناء يبدا وحدو عند كل push على `main`.

---

## 🗂️ بنية المشروع

```
lib/
├── main.dart                    نقطة الدخول + RTL + اللغة
├── core/
│   ├── config/env.dart          مفاتيح Supabase
│   ├── network/                 طبقة الشبكة (Supabase + الأخطاء)
│   ├── models/models.dart       كل النماذج
│   ├── theme/app_theme.dart     الهوية البصرية (ألوان/خطوط/ظلال)
│   ├── router/app_router.dart   go_router + حماية المسارات
│   ├── utils/dz_locations.dart  69 ولاية · 1541 بلدية
│   └── widgets/ui_kit.dart      مكوّنات موحّدة
├── features/
│   ├── onboarding/              اختيار: زبون / تاجر
│   ├── auth/                    دخول التاجر
│   ├── customer/                المتجر · المنتج · السلة · Checkout · التتبع
│   └── merchant/                لوحة · طلبات · منتجات · متابعات · إعدادات
└── shared/providers/            Riverpod (السلة، الكتالوج، الطلبات، Realtime)

supabase/01_schema.sql           كلشي: جداول + RLS + Triggers + RPC + Storage
assets/data/algeria.json         69 ولاية / 1541 بلدية (الجريدة الرسمية 2026)
assets/fonts/Tajawal-*.ttf       الخط العربي (مضمّن)
assets/icon/                     الأيقونة + السبلاش
```

---

## 🗄️ قاعدة البيانات

| الجدول | الوظيفة |
|---|---|
| `profiles` | المستخدمين + الدور (`merchant` / `customer`) |
| `stores` | المتاجر |
| `store_delivery_rates` | سعر التوصيل لكل ولاية |
| `categories` | الأصناف |
| `products` | المنتجات + المتغيّرات (`variant_schema` jsonb) |
| `product_variants` | تركيبات (لون/مقاس) بمخزون مستقل |
| `orders` | الطلبات (COD) |
| `order_items` | سطور الطلب |
| `abandoned_leads` | السلات المتروكة |
| `notifications` | إشعارات التاجر |
| `cart_items` | سلات محفوظة |

### دوال RPC
| الدالة | الوظيفة |
|---|---|
| `place_order(...)` | **طلب كامل فـtransaction واحد** — يتحقق من المخزون والأسعار |
| `track_order(number, phone)` | تتبع آمن للزبون بلا حساب |
| `store_stats(store_id, days)` | إحصائيات اللوحة |

### Triggers تلقائية
- إنشاء `profile` عند التسجيل
- حساب `total_price` من `order_items` (ماشي من الكلاينت)
- خصم المخزون عند `confirmed` · رجّعو عند `canceled`
- إشعار التاجر عند كل طلب جديد

### الأمان (RLS)
- ✅ الزبون **يقدر ينشئ** طلب بلا حساب
- ❌ **ما يقدرش يقرا** حتى طلب
- ✅ التاجر يشوف غير متجرو
- ✅ المنتجات المفعّلة فقط ظاهرة للعامة

---

## 🎨 الهوية

- **أخضر جزائري:** `#0A6942` · **ذهبي:** `#D8A31A`
- **الخط:** Tajawal (مضمّن — بلا إنترنت)
- **RTL** مفروض على كل التطبيق
- **العملة:** دج بفواصل آلاف

---

## ✅ اللي يخدم

**الزبون**
- [x] استعراض + بحث + فلترة + ترتيب
- [x] صفحة منتج (كاروس، متغيّرات، كمية)
- [x] سلة محلية (بلا تسجيل)
- [x] Checkout COD — **5 حقول فقط**
- [x] 69 ولاية + 1541 بلدية
- [x] شاشة نجاح برقم الطلب
- [x] تتبع الطلب بالهاتف

**التاجر**
- [x] لوحة تحكم بإحصائيات
- [x] طلبات لحظية (Realtime) + فلترة بالحالة
- [x] تغيير الحالة من مكان واحد
- [x] اتصال + واتساب بضغطة
- [x] منتجات CRUD + رفع صور لـSupabase Storage
- [x] متغيّرات المنتج (لون/مقاس)
- [x] متابعة السلات المتروكة + واتساب جاهز
- [x] **بون توصيل** جاهز للطباعة
- [x] إعدادات المتجر

---

## 🚧 خارطة الطريق

- [ ] تصدير الطلبات لـYalidine / ZR Express (API)
- [ ] طباعة حرارية عبر Bluetooth
- [ ] إشعارات Push (FCM)
- [ ] OTP بالهاتف
- [ ] كوبونات الخصم
- [ ] متعدد المتاجر فـتطبيق واحد

---

## 📄 الترخيص

MIT — استعملو كيفما حبيت.
