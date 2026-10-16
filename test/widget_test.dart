import 'package:flutter_test/flutter_test.dart';
import 'package:pelelangan_produk_fashion/src/app/lelang_fashion_app.dart';
import 'package:pelelangan_produk_fashion/src/core/utils/date_parser.dart';
import 'package:pelelangan_produk_fashion/src/data/models/auction_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to auth screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LelangFashionApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Masuk ke aplikasi'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });

  test('parses auction product response', () {
    final product = AuctionProduct.fromJson({
      'id': 1,
      'title': 'Jaket Denim',
      'description': 'Deskripsi',
      'category': 'Jaket',
      'condition': 'Baru',
      'brand': 'Brand',
      'size': 'L',
      'image_url': null,
      'starting_price': 100000,
      'bid_increment': 10000,
      'current_highest_bid': 120000,
      'minimum_next_bid': 130000,
      'starts_at': '2026-05-08T08:00:00Z',
      'ends_at': '2026-05-08T10:00:00Z',
      'status': 'active',
      'is_favorited': true,
      'closed_at': null,
      'winner': null,
      'bids': [
        {
          'id': 1,
          'amount': 120000,
          'created_at': '2026-05-08T08:30:00Z',
          'user': {'id': 2, 'name': 'Ardian'},
        },
      ],
    });

    expect(product.title, 'Jaket Denim');
    expect(product.isFavorited, isTrue);
    expect(product.bids.single.userName, 'Ardian');
  });

  test('parses API timestamps as Jakarta time', () {
    final parsed = parseDate('2026-05-08T08:30:00Z');

    expect(parsed?.year, 2026);
    expect(parsed?.month, 5);
    expect(parsed?.day, 8);
    expect(parsed?.hour, 15);
    expect(parsed?.minute, 30);
  });

  test('keeps business-local timestamps without timezone', () {
    final parsed = parseDate('2026-05-08 15:30:00');

    expect(parsed?.hour, 15);
    expect(parsed?.minute, 30);
  });
}
