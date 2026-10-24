# 🏗️ معمارية LATCHI STORE DZ

## نظرة عامة

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (Android/iOS)                  │
│                                                               │
│  ┌────────────────────────┐  ┌────────────────────────────┐  │
│  │   CUSTOMER SHELL       │  │    MERCHANT SHELL          │  │
│  │   /shop                │  │    /merchant               │  │
│  │                        │  │                            │  │
│  │  Home · Cart · Orders  │  │  Dashboard · Orders        │  │
│  │  Profile               │  │  Products · Leads          │  │
│  └───────────┬────────────┘  └─────────────┬──────────────┘  │
│              │                              │                 │
│              └──────────┬───────────────────┘                 │
│                         │                                     │
│              ┌──────────▼──────────┐                          │
│              │   core/ (shared)    │                          │
│              │  theme · models     │                          │
│              │  router · network   │                          │
│              │  ui_kit · utils     │                          │
│              └──────────┬──────────┘                          │
│                         │                                     │
│              ┌──────────▼──────────┐                          │
│              │ shared/providers/   │  ← Riverpod              │
│              │ cart · products     │                          │
│              │ orders · leads      │                          │
│              └──────────┬──────────┘                          │
└─────────────────────────┼─────────────────────────────────────┘
                          │ HTTPS / WebSocket
              ┌───────────▼────────────┐
              │      SUPABASE          │
              │                        │
              │  Postgres ─── RLS      │
              │  Auth (GoTrue)         │
              │  Storage (3 buckets)   │
              │  Realtime (orders)     │
              │  RPC: place_order      │
              └────────────────────────┘
```

---

## قرارات معمارية

### 1. واجهتان، codebase واحد
**بدل** تطبيقين منفصلين، استعملنا **Persona Switch**:
- `roleProvider` يحفظ الاختيار فـ`SharedPreferences`
- `go_router.redirect` يمنع التاجر يدخل `/shop` والعكس
- نفس الـ`core/` و`shared/providers/` للزوز

**لماذا؟** نشر واحد، تحديث واحد، صيانة وحدة. والتبديل فوري للاختبار.

### 2. Riverpod بدل Bloc
- `StateNotifierProvider` للسلة (منطق متزامن بسيط)
- `FutureProvider` للبيانات الشبكية (كاش تلقائي + invalidate)
- `StreamProvider` للـRealtime
- `Provider.family` لتفاصيل عنصر واحد

**لماذا؟** أقل boilerplate، كاش مدمج، `ref.invalidate` = تحديث فوري بلا events.

### 3. Checkout عبر RPC وليس inserts
```dart
// ❌ ماشي هاكا:
await client.from('orders').insert(...);
await client.from('order_items').insert(...);

// ✅ هاكا:
final res = await client.rpc('place_order', params: {...});
```
`place_order` PL/pgSQL:
1. تتحقق من وجود المنتج وانتمائه للمتجر
2. تتحقق من المخزون
3. تجيب السعر **من الداتابيز** ماشي من الكلاينت
4. تحسب التوصيل من `store_delivery_rates`
5. تنشئ الطلب + السطور فـ**transaction واحد**
6. ترجع `order_number` و`total`

**لماذا؟** الزبون ما يقدرش يزوّر السعر ولا المخزون. وأي فشل = rollback كامل.

### 4. RLS بدل API keys
| العملية | anon | customer | merchant |
|---|---|---|---|
| قراءة منتجات مفعّلة | ✅ | ✅ | ✅ |
| إنشاء طلب | ✅ | ✅ | ✅ |
| **قراءة طلبات** | ❌ | غير طلباتو | غير متجرو |
| تعديل منتج | ❌ | ❌ | ✅ (متجرو) |
| رفع صورة | ❌ | ❌ | ✅ (`/{uid}/...`) |

### 5. الصور: Storage + RLS على المسار
```
product-images/{user_id}/{timestamp}_{filename}
                └──────┘
        RLS: (storage.foldername(name))[1] = auth.uid()
```
تاجر ما يقدرش يكتب فمجلد تاجر آخر.

### 6. البيانات المحلية: السلة
السلة **محلية 100%** (`StateNotifier` فـالذاكرة) — ما تحتاجش شبكة ولا حساب.
`abandoned_leads` تتحفظ **بعد** ما يدخل رقم هاتف صحيح (ماشي مع كل حرف).

**لماذا؟** ما نزعجوش الزبون، ونحافظو على الـleads الحقيقية فقط.

### 7. الولايات والبلديات: محلي وليس API
`assets/data/algeria.json` — 88KB — 69 ولاية / 1541 بلدية.
محمّل مرة وحدة عند الـbootstrap.

**لماذا؟** يخدم **بلا إنترنت**، أسرع بزاف من round-trip، ومصدره الجريدة الرسمية (قانون 26-06، أفريل 2026).

> ⚠️ **مهم:** أغلب التطبيقات الجزائرية مازالت على **58 ولاية**. هادا على **69** (الولايات 59–69 الجديدة).

---

## تدفق الطلب (End-to-End)

```
الزبون                          Supabase                      التاجر
──────                          ────────                      ──────
1. يضيف للسلة (محلي)
2. يفتح Checkout
3. يكتب رقم الهاتف ──────────► INSERT abandoned_lead
                                (بسكات، ماشي blocking)
4. يكمّل النموذج
5. "أكّد الطلب" ──────────────► RPC place_order
                                  ├─ تحقق مخزون
                                  ├─ حساب الأسعار
                                  ├─ INSERT order
                                  ├─ INSERT order_items
                                  ├─ TRIGGER recalc_total
                                  └─ TRIGGER notify_new_order
                                                              ◄── Realtime push
                                                             6. يشوف الطلب
                                                             7. "أكّد" ──► TRIGGER
                                                                            خصم المخزون
8. يشوف رقم الطلب
9. يتبّع بـtrack_order ◄────── RPC track_order
```

---

## الحالات (State Machine)

```
                    ┌─────────┐
                    │  جديد   │
                    └────┬────┘
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
     ┌────────┐    ┌──────────┐   ┌────────┐
     │ مؤجل   │    │ تم التأكيد│   │  ملغى  │
     └───┬────┘    └────┬─────┘   └────────┘
         │              │ (خصم مخزون)
         │              ▼
         │         ┌──────────────┐
         │         │ قيد التوصيل  │
         │         └──────┬───────┘
         │                ▼
         │         ┌──────────────┐
         └────────►│ تم التوصيل   │
       (تأكيد)     └──────────────┘
```

`OrderStatus.next` فـ`models.dart` ترمّز هادا — الواجهة تولّد الأزرار منها تلقائياً.

---

## أداء

| القياس | القيمة |
|---|---|
| حجم APK | ~22 MB |
| وقت الإقلاع | < 2s (بارد) |
| البيانات المحمّلة عند البدء | 88 KB (ولايات) |
| صور | `cached_network_image` + شيمر |
| استعلامات | limit 200 طلب، 100 lead |

---

## نقاط التوسّع

### تعدد المتاجر (Marketplace)
`publicStoreProvider` تاخذ **أول** متجر. للتحويل لماركت بليس:
```dart
// بدل .limit(1) ⇒ قائمة متاجر + شاشة اختيار
final storesProvider = FutureProvider<List<Store>>(...);
// و productsProvider تاخذ storeId كـfamily param
```

### Yalidine / ZR Express
فـ`order_detail_screen.dart` كاين `_labelText()` — يتحوّل لـJSON payload:
```dart
{'order_id': ..., 'to_wilaya': o.wilayaCode, 'to_commune': o.communeName, ...}
```
ويتبعث لـAPI تاعهم.

### طباعة حرارية
`printing` package موجود فـ`pubspec`. `_showLabel` يتحوّل لـ`PdfPreview` بـESC/POS.
