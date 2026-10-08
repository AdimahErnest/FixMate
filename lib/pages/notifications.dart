import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    return Scaffold(
      appBar: AppBar(title: Text(t('Notifications'))),
      body: state.notifications.isEmpty
          ? Center(child: Text(t('No notifications yet.')))
          : RefreshIndicator(
              onRefresh: () async {
                state.startNotificationStream();
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Card(
                    color: notification.isRead
                        ? null
                        : FixMateTheme.gold.withValues(alpha: .09),
                    child: ListTile(
                      leading: Icon(
                        notification.type == 'paid_order'
                            ? Icons.shopping_bag_outlined
                            : Icons.local_shipping_outlined,
                        color: FixMateTheme.gold,
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      trailing: notification.isRead
                          ? null
                          : const Icon(Icons.circle, size: 10, color: FixMateTheme.gold),
                      onTap: () async {
                        try {
                          await state.markNotificationRead(notification);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
