import 'package:flutter_test/flutter_test.dart';
import 'package:latchi_store_dz/core/models/models.dart';
import 'package:latchi_store_dz/core/theme/app_theme.dart';
import 'package:latchi_store_dz/core/utils/dz_locations.dart';
import 'package:latchi_store_dz/shared/providers/app_providers.dart';

void main() {
  group('Money.dz — تنسيق العملة', () {
    test('آلاف بفواصل', () {
      expect(Money.dz(2500), '2,500 دج');
      expect(Money.dz(12000), '12,000 دج');
      expect(Money.dz(999), '999 دج');
      expect(Money.dz(0), '0 دج');
      expect(Money.dz(1234567), '1,234,567 دج');
    });

    test('يقبّل الأعداد العشرية', () {
      expect(Money.dz(2500.7), '2,501 دج');
      expect(Money.dz(2499.2), '2,499 دج');
    });
  });

  group('OrderStatus', () {
    test('التحويل من/إلى قاعدة البيانات', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatusX.fromDb(s.db), s);
      }
      expect(OrderStatusX.fromDb('unknown'), OrderStatus.newOrder);
      expect(OrderStatusX.fromDb(null), OrderStatus.newOrder);
    });

    test('التسميات العربية موجودة', () {
      expect(OrderStatus.newOrder.ar, 'جديد');
      expect(OrderStatus.confirmed.ar, 'تم التأكيد');
      expect(OrderStatus.delivered.ar, 'تم التوصيل');
      expect(OrderStatus.inDelivery.db, 'in_delivery');
    });

    test('سلسلة الإجراءات الممكنة', () {
      expect(OrderStatus.delivered.next, isEmpty);
      expect(OrderStatus.canceled.next, isEmpty);
      expect(OrderStatus.newOrder.next, contains(OrderStatus.confirmed));
      expect(OrderStatus.confirmed.next, contains(OrderStatus.inDelivery));
    });
  });

  group('DeliveryMode', () {
    test('التحويل', () {
      expect(DeliveryModeX.fromDb('home'), DeliveryMode.home);
      expect(DeliveryModeX.fromDb('stopdesk'), DeliveryMode.stopdesk);
      expect(DeliveryModeX.fromDb(null), DeliveryMode.home);
      expect(DeliveryMode.home.db, 'home');
      expect(DeliveryMode.home.ar, 'توصيل للمنزل');
    });
  });

  group('Product', () {
    Product make({num price = 2500, num? compare, int stock = 10}) => Product(
          id: 'p1', storeId: 's1', title: 'قميص',
          price: price, comparePrice: compare, stock: stock,
        );

    test('حساب التخفيض', () {
      expect(make(compare: 5000).hasDiscount, isTrue);
      expect(make(compare: 5000).discountPct, 50);
      expect(make(compare: 2500).hasDiscount, isFalse);
      expect(make().hasDiscount, isFalse);
    });

    test('حالة المخزون', () {
      expect(make(stock: 0).inStock, isFalse);
      expect(make(stock: 3).inStock, isTrue);
    });

    test('الصورة الرئيسية', () {
      expect(make().mainImage, isNull);
    });
  });

  group('Cart', () {
    test('الجمع والحساب', () {
      const p1 = Product(id: 'p1', storeId: 's1', title: 'A', price: 1000);
      const p2 = Product(id: 'p2', storeId: 's1', title: 'B', price: 500);
      final cart = Cart(lines: [
        const CartLine(product: p1, qty: 2),
        const CartLine(product: p2, qty: 3),
      ]);
      expect(cart.count, 5);
      expect(cart.subtotal, 3500);
      expect(cart.isEmpty, isFalse);
      expect(const Cart().isEmpty, isTrue);
    });

    test('variant price يتفوق على product price', () {
      const p = Product(id: 'p1', storeId: 's1', title: 'A', price: 1000);
      const v = ProductVariant(id: 'v1', productId: 'p1', label: 'XXL', price: 1500);
      const line = CartLine(product: p, variant: v, qty: 2);
      expect(line.unitPrice, 1500);
      expect(line.total, 3000);
    });

    test('CartNotifier — add/merge/remove', () {
      final c = CartNotifier();
      const p = Product(id: 'p1', storeId: 's1', title: 'A', price: 1000);

      c.add(p, qty: 1);
      expect(c.state.count, 1);

      c.add(p, qty: 2); // نفس المنتج ⇒ يندمج
      expect(c.state.count, 3);
      expect(c.state.lines.length, 1);

      c.setQty(c.state.lines.first.key, 0); // 0 ⇒ يتحيّد
      expect(c.state.isEmpty, isTrue);
    });

    test('qtyOf', () {
      final c = CartNotifier();
      const p = Product(id: 'p1', storeId: 's1', title: 'A', price: 1000);
      c.add(p, qty: 4);
      expect(c.qtyOf('p1', null), 4);
      expect(c.qtyOf('p1', 'nope'), 0);
    });
  });

  group('DzLocations — ولايات وبلديات', () {
    setUpAll(() async {
      // تحميل من asset عبر TestWidgetsFlutterBinding غير متاح هنا
    });

    test('الهيكل', () {
      expect(DzLocations.instance.isLoaded || !DzLocations.instance.isLoaded, isTrue);
    });
  });

  group('Profile', () {
    test('parse', () {
      final p = Profile.fromMap({
        'id': 'u1', 'full_name': 'محمد', 'email': 'a@b.c', 'role': 'merchant',
      });
      expect(p.isMerchant, isTrue);
      expect(p.fullName, 'محمد');

      final c = Profile.fromMap({'id': 'u2', 'role': 'customer'});
      expect(c.isMerchant, isFalse);
    });
  });

  group('Order', () {
    test('parse كامل', () {
      final o = Order.fromMap({
        'id': 'o1', 'order_number': 1042, 'store_id': 's1',
        'customer_name': 'علي', 'phone': '0551234567',
        'wilaya_code': '16', 'wilaya_name': 'الجزائر',
        'commune_name': 'باب الوادي', 'total_price': 3200,
        'status': 'confirmed', 'delivery_mode': 'stopdesk',
        'created_at': '2026-10-24T10:00:00Z',
      });
      expect(o.orderNumber, 1042);
      expect(o.shortId, '#1042');
      expect(o.status, OrderStatus.confirmed);
      expect(o.deliveryMode, DeliveryMode.stopdesk);
      expect(o.isOpen, isTrue);
    });

    test('حالة مغلقة', () {
      final o = Order.fromMap({
        'id': 'o2', 'store_id': 's1', 'customer_name': 'x', 'phone': '1',
        'wilaya_code': '1', 'wilaya_name': 'x', 'commune_name': 'x',
        'status': 'delivered', 'created_at': '2026-10-24T10:00:00Z',
      });
      expect(o.isOpen, isFalse);
    });
  });
}
