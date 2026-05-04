import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientesState {
  final List<dynamic> clients;
  final bool isLoading;
  final String? errorMessage;
  
  ClientesState({
    this.clients = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ClientesState copyWith({
    List<dynamic>? clients,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClientesState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ClientesNotifier extends StateNotifier<ClientesState> {
  ClientesNotifier() : super(ClientesState());

  Future<void> loadClients(String collectorId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final response = await Supabase.instance.client
          .from('clients')
          .select('id, name, cedula, phone, address, traffic_light, is_punished, last_contact_at, rating')
          .eq('created_by_id', collectorId)
          .eq('is_active', true)
          .order('name', ascending: true);
          
      state = state.copyWith(clients: response as List<dynamic>, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> createClient({
    required String collectorId,
    required String name,
    required String cedula,
    required String phone,
    required String address,
    String? email,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await Supabase.instance.client.from('clients').insert({
        'created_by_id': collectorId,
        'name': name,
        'cedula': cedula,
        'phone': phone,
        'address': address,
        if (email != null && email.isNotEmpty) 'email': email,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      await loadClients(collectorId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final clientesProvider = StateNotifierProvider<ClientesNotifier, ClientesState>((ref) {
  return ClientesNotifier();
});
