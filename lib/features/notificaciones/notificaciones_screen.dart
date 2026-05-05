import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/auth_provider.dart';
import 'notificaciones_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authNotifierProvider).user?.id;
      if (userId != null) {
        ref.read(notificacionesProvider.notifier).loadNotifications(userId);
      }
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'INACTIVITY_ALERT':
        return Icons.warning_amber_rounded;
      case 'PAYMENT_RECEIVED':
        return Icons.check_circle_outline;
      case 'LOAN_CREATED':
        return Icons.add_circle_outline;
      case 'LOAN_DEFAULTED':
        return Icons.cancel_outlined;
      case 'CAJA_CLOSED':
        return Icons.lock_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'INACTIVITY_ALERT':
        return Colors.orange;
      case 'PAYMENT_RECEIVED':
        return Colors.green;
      case 'LOAN_CREATED':
        return Colors.blue;
      case 'LOAN_DEFAULTED':
        return Colors.red;
      case 'CAJA_CLOSED':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificacionesProvider);
    final user = ref.watch(authNotifierProvider).user;
    final userId = user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1220),
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.unreadCount > 0 && userId != null)
            TextButton(
              onPressed: () => ref.read(notificacionesProvider.notifier).markAllAsRead(userId),
              child: const Text(
                'Marcar todas leídas',
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId != null) {
            await ref.read(notificacionesProvider.notifier).loadNotifications(userId);
          }
        },
        child: _buildContent(state, userId),
      ),
    );
  }

  Widget _buildContent(NotificacionesState state, String? userId) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.notifications.isEmpty) {
      return const Center(
        child: Text(
          'Sin notificaciones',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        final bool isRead = notification['is_read'] ?? false;
        final String type = notification['type'] ?? '';
        final String title = notification['title'] ?? '';
        final String message = notification['message'] ?? '';
        final String createdAtStr = notification['created_at'] ?? '';
        
        DateTime? createdAt;
        if (createdAtStr.isNotEmpty) {
          createdAt = DateTime.parse(createdAtStr).toLocal();
        }

        final formattedDate = createdAt != null 
            ? DateFormat('d MMM yyyy h:mm a').format(createdAt)
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isRead ? const Color(0xFF1B2333) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              if (!isRead && userId != null) {
                ref.read(notificacionesProvider.notifier).markAsRead(notification['id'].toString(), userId);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: !isRead 
                    ? const Border(left: BorderSide(color: Color(0xFF2563EB), width: 4))
                    : null,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getIcon(type),
                    color: isRead ? _getIconColor(type) : const Color(0xFF2563EB),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isRead ? Colors.white : Colors.black,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isRead ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: isRead ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
