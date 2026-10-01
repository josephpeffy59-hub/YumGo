import 'package:flutter/material.dart';
import '../../api.dart';
import '../../theme.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/orders/mine');
      setState(() => _orders = r as List);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.deepOrange;
      case 'READY':
        return Colors.green;
      case 'DELIVERED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.grey;
    }
    return kRed;
  }

  bool _canCancel(String status) =>
      status == 'PENDING' || status == 'ACCEPTED';

  Future<void> _cancel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The restaurant will be notified. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep it',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancellingId = id);
    try {
      await Api.patch('/orders/$id/cancel', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: kRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Icon(Icons.receipt_long, size: 64, color: kBorder),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No orders yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _orderCard(_orders[i]),
                  ),
      ),
    );
  }

  Widget _orderCard(dynamic o) {
    final status = o['status'] as String? ?? 'PENDING';
    final color = _statusColor(status);
    final items = List<Map<String, dynamic>>.from(o['items'] ?? []);
    final cancellable = _canCancel(status);
    final isCancelling = _cancellingId == o['id'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o['restaurant']?['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (it) => Text(
                '${it['quantity']} x ${it['menuItem']?['name'] ?? ''}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  '#${o['id'].toString().substring(0, 6)}',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${(o['total'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kRed,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (cancellable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isCancelling ? null : () => _cancel(o['id']),
                  icon: isCancelling
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            color: kRed,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(
                    isCancelling ? 'Cancelling...' : 'Cancel order',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}