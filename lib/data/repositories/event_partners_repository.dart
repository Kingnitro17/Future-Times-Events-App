import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event_partner.dart';

class EventPartnersRepository {
  EventPartnersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<EventPartner>> getPartners(String eventId) async {
    final rows = await _client
        .from('event_partners')
        .select()
        .eq('event_id', eventId)
        .order('sort_order')
        .order('name');
    return rows
        .map<EventPartner>((row) => EventPartner.fromSupabase(row))
        .toList(growable: false);
  }

  Future<EventPartner> addPartner({
    required String eventId,
    required String name,
    String? logoUrl,
    String? websiteUrl,
    String tier = 'partner',
  }) async {
    final row = await _client
        .from('event_partners')
        .insert({
          'event_id': eventId,
          'name': name.trim(),
          'logo_url': logoUrl,
          'website_url': websiteUrl,
          'tier': tier,
        })
        .select()
        .single();
    return EventPartner.fromSupabase(row);
  }

  Future<void> updatePartner({
    required String partnerId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('event_partners').update(data).eq('id', partnerId);
  }

  Future<void> deletePartner(String partnerId) async {
    await _client.from('event_partners').delete().eq('id', partnerId);
  }

  Future<bool> eventHasFtService(String eventId) async {
    final result = await _client.rpc(
      'event_has_ft_service',
      params: {'p_event_id': eventId},
    );
    return result == true;
  }
}
