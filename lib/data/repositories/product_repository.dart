import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organizer_product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<OrganizerProduct>> getEventProducts(String eventId) async {
    final rows = await _client
        .from('organizer_products')
        .select()
        .eq('event_id', eventId)
        .eq('is_active', true)
        .order('created_at');
    return rows
        .map((row) => OrganizerProduct.fromJson(row))
        .toList(growable: false);
  }

  Future<List<OrganizerProduct>> getManagedProducts(String eventId) async {
    final rows = await _client
        .from('organizer_products')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => OrganizerProduct.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ProductPreorder>> getEventPreorders(String eventId) async {
    final rows = await _client
        .from('product_preorders')
        .select('*, organizer_products(name)')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => ProductPreorder.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ProductPreorder>> getMyPreorders({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('product_preorders')
        .select('*, organizer_products(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .map((row) => ProductPreorder.fromJson(row))
        .toList(growable: false);
  }

  Future<OrganizerProduct> saveProduct({
    String? productId,
    required String eventId,
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    required String currency,
    required int? stockQuantity,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to manage products.');
    final values = {
      'event_id': eventId,
      'organizer_id': userId,
      'name': name.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
      'price': price,
      'currency': currency.trim().toUpperCase(),
      'stock_quantity': stockQuantity,
      'is_active': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = productId == null
        ? await _client
            .from('organizer_products')
            .insert(values)
            .select()
            .single()
        : await _client
            .from('organizer_products')
            .update(values)
            .eq('id', productId)
            .eq('event_id', eventId)
            .select()
            .single();
    return OrganizerProduct.fromJson(row);
  }

  Future<void> archiveProduct(String productId) async {
    await _client.from('organizer_products').update({
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String()
    }).eq('id', productId);
  }

  Future<void> updatePreorderStatus(String preorderId, String status) async {
    await _client
        .from('product_preorders')
        .update({'status': status}).eq('id', preorderId);
  }

  Future<ProductPreorder> createPreorder({
    required String productId,
    required int quantity,
    String? notes,
  }) async {
    final result = await _client.rpc('create_product_preorder', params: {
      'p_product_id': productId,
      'p_quantity': quantity,
      'p_notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    });
    final id = result.toString();
    final row = await _client
        .from('product_preorders')
        .select('*, organizer_products(name)')
        .eq('id', id)
        .single();
    return ProductPreorder.fromJson(row);
  }
}
