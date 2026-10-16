import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/auction_product.dart';
import '../models/auction_product_page.dart';
import '../models/auction_settlement.dart';
import '../models/auth_result.dart';
import '../models/bid_record.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/identity_verification.dart';
import '../models/second_chance_offer.dart';
import '../models/user_account.dart';

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;
  String? token;

  Future<AuthResult> register(
    String name,
    String email,
    String password,
    String confirm,
  ) async {
    final json = await _post('/daftar', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirm,
    });
    return AuthResult.fromJson(json);
  }

  Future<AuthResult> login(String email, String password) async {
    final json = await _post('/masuk', {'email': email, 'password': password});
    return AuthResult.fromJson(json);
  }

  Future<UserAccount> me() async {
    final json = await _get('/saya');
    return UserAccount.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _post('/keluar', {});
  }

  Future<UserAccount> resendWhatsappOtp() async {
    final json = await _post('/whatsapp/kirim-otp', {});
    if (json['user'] is Map<String, dynamic>) {
      return UserAccount.fromJson(json['user'] as Map<String, dynamic>);
    }
    return me();
  }

  Future<UserAccount> updateWhatsapp(String whatsapp) async {
    final json = await _post('/whatsapp/nomor', {'nomor_whatsapp': whatsapp});
    return UserAccount.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<UserAccount> verifyWhatsappOtp(String code) async {
    final json = await _post('/whatsapp/verifikasi-otp', {'kode': code});
    return UserAccount.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<IdentityVerification?> identityVerification() async {
    final json = await _get('/verifikasi-identitas');
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return IdentityVerification.fromJson(data);
    }
    return null;
  }

  Future<IdentityVerification> submitIdentityVerification({
    required String nik,
    required String name,
    required XFile ktp,
    required XFile selfie,
  }) async {
    final json = await _multipart(
      '/verifikasi-identitas',
      fields: {'nik': nik, 'nama_ktp': name},
      files: {'foto_ktp': ktp.path, 'foto_selfie': selfie.path},
    );
    return IdentityVerification.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<AuctionProduct>> auctionProducts({
    String? status,
    String? query,
  }) async {
    final page = await auctionProductsPage(status: status, query: query);
    return page.items;
  }

  Future<AuctionProductPage> auctionProductsPage({
    String? status,
    String? query,
    int page = 1,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    params['page'] = page.toString();
    final json = await _get('/produk-lelang', params: params);
    return AuctionProductPage.fromJson(json);
  }

  Future<AuctionProduct> auctionProduct(int id) async {
    final json = await _get('/produk-lelang/$id');
    return AuctionProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuctionProductPage> favoriteAuctionProductsPage({int page = 1}) async {
    final json = await _get(
      '/produk-lelang-favorit',
      params: {'page': page.toString()},
    );
    return AuctionProductPage.fromJson(json);
  }

  Future<AuctionProduct> favoriteAuctionProduct(int productId) async {
    final json = await _post('/produk-lelang/$productId/favorit', {});
    return AuctionProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuctionProduct> unfavoriteAuctionProduct(int productId) async {
    final json = await _delete('/produk-lelang/$productId/favorit');
    return AuctionProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuctionProduct> placeBid(int productId, int amount) async {
    final json = await _post('/produk-lelang/$productId/penawaran', {
      'amount': amount,
    });
    return AuctionProduct.fromJson(
      json['auction_product'] as Map<String, dynamic>,
    );
  }

  Future<List<BidRecord>> myBids() async {
    final json = await _get('/penawaran-saya');
    return _dataList(json).map(BidRecord.fromJson).toList();
  }

  Future<List<AuctionProduct>> myWins() async {
    final json = await _get('/kemenangan-saya');
    return _dataList(json).map(AuctionProduct.fromJson).toList();
  }

  Future<List<AuctionSettlement>> mySettlements() async {
    final json = await _get('/pelunasan-saya');
    return _dataList(json).map(AuctionSettlement.fromJson).toList();
  }

  Future<String> startSettlementPayment(int settlementId) async {
    final json = await _post('/pelunasan/$settlementId/checkout', {});
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final paymentUrl = data['payment_url'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw const FormatException(
        'Duitku tidak mengembalikan tautan pembayaran.',
      );
    }
    return paymentUrl;
  }

  Future<List<SecondChanceOffer>> secondChanceOffers() async {
    final json = await _get('/penawaran-kedua');
    return _dataList(json).map(SecondChanceOffer.fromJson).toList();
  }

  Future<void> acceptSecondChance(int offerId) async {
    await _post('/penawaran-kedua/$offerId/terima', {});
  }

  Future<void> rejectSecondChance(int offerId) async {
    await _post('/penawaran-kedua/$offerId/tolak', {});
  }

  Future<List<ChatThread>> chatThreads() async {
    final json = await _get('/chat/threads');
    return _dataList(json).map(ChatThread.fromJson).toList();
  }

  Future<ChatThread?> chatThread(int threadId) async {
    try {
      final json = await _get('/chat/threads/$threadId');
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return ChatThread.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ChatThread> startProductChat(int productId) async {
    final json = await _post('/produk-lelang/$productId/chat', {});
    return ChatThread.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> chatMessages(int threadId) async {
    final json = await _get('/chat/threads/$threadId/messages');
    return _dataList(json).map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendChatMessage(int threadId, String body) async {
    final json = await _post('/chat/threads/$threadId/messages', {
      'body': body,
    });
    return ChatMessage.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ChatThread> markChatRead(int threadId) async {
    final json = await _post('/chat/threads/$threadId/read', {});
    return ChatThread.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: _headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _multipart(
    String path, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);
    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }

    if (body is Map<String, dynamic>) {
      if (body['errors'] is Map) {
        final errors = body['errors'] as Map;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          throw Exception(first.first.toString());
        }
      }
      if (body['message'] != null) {
        throw Exception(body['message'].toString());
      }
    }

    throw Exception('Request gagal (${response.statusCode}).');
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
