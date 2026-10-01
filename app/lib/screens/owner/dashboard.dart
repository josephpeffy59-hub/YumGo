import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api.dart';
import '../../state/auth.dart';
import '../../theme.dart';
import '../customer/chats.dart' show ChatScreen;

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _tab = 0;
  Map<String, dynamic>? _restaurant;
  List<dynamic> _orders = [];
  List<dynamic> _menu = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rest = await Api.get('/restaurants/mine');
      _restaurant = rest;
      if (rest != null) {
        final results = await Future.wait([
          Api.get('/orders/incoming'),
          Api.get('/menu/restaurant/${rest['id']}'),
        ]);
        _orders = results[0] as List;
        _menu = results[1] as List;
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
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _pendingCount =>
      _orders.where((o) => o['status'] == 'PENDING').length;

  double get _revenue => _orders.fold(
        0.0,
        (s, o) => s + (o['total'] as num).toDouble(),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }

    if (_restaurant == null) {
      return _createRestaurantPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: kRed),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _overviewTab(),
          _ordersTab(),
          _menuTab(),
          const _OwnerChatsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        ],
      ),
    );
  }

  // -------------------- OVERVIEW --------------------
  Widget _overviewTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kRed, kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today at a glance',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _restaurant!['name'] ?? '',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _restaurant!['address'] ?? 'No address set',
                    style: const TextStyle(color: kWhite, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Orders',
                    '${_orders.length}',
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Pending',
                    '$_pendingCount',
                    Icons.pending_actions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Menu items',
                    '${_menu.length}',
                    Icons.menu_book,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Revenue',
                    '\$${_revenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthState>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kRed, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- ORDERS --------------------
  Widget _ordersTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: _orders.isEmpty
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

  Widget _orderCard(dynamic o) {
    final status = o['status'] as String? ?? 'PENDING';
    final color = _statusColor(status);
    final items = List<Map<String, dynamic>>.from(o['items'] ?? []);
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
                    'Order #${o['id'].toString().substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 6),
            Text(
              '${o['customer']?['name'] ?? ''}'
              '${o['customer']?['phone'] != null ? ' • ${o['customer']['phone']}' : ''}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const Divider(height: 20),
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${it['quantity']} x ${it['menuItem']?['name'] ?? ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${(o['total'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kRed,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: kRed),
                  onSelected: (newStatus) =>
                      _updateStatus(o['id'], newStatus),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'ACCEPTED', child: Text('Accept')),
                    PopupMenuItem(value: 'PREPARING', child: Text('Preparing')),
                    PopupMenuItem(value: 'READY', child: Text('Ready')),
                    PopupMenuItem(value: 'DELIVERED', child: Text('Delivered')),
                    PopupMenuItem(value: 'CANCELLED', child: Text('Cancel')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await Api.patch('/orders/$id/status', {'status': status});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  // -------------------- MENU --------------------
  Widget _menuTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddMenuItem,
                icon: const Icon(Icons.add),
                label: const Text('Add menu item'),
              ),
            ),
            const SizedBox(height: 12),
            if (_menu.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No menu items yet',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ..._menu.map((m) => _menuCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(dynamic m) {
    return Card(
      child: ListTile(
        leading: m['imageUrl'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: Api.url(m['imageUrl']),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.fastfood, color: kRed),
                ),
              )
            : const Icon(Icons.fastfood, color: kRed),
        title: Text(m['name'] ?? ''),
        subtitle: Text(
          '\$${m['price']}  •  ${m['category'] ?? 'Uncategorized'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: kRed),
          onPressed: () => _deleteMenuItem(m['id']),
        ),
      ),
    );
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.delete('/menu/$id');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  void _showAddMenuItem() {
    final name = TextEditingController();
    final price = TextEditingController();
    final category = TextEditingController();
    final desc = TextEditingController();
    String? imageUrl;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final xfile =
                  await picker.pickImage(source: ImageSource.gallery);
              if (xfile == null) return;
              setModal(() => uploading = true);
              final bytes = await xfile.readAsBytes();
              final url = await Api.uploadImageBytes(bytes, xfile.name);
              setModal(() {
                imageUrl = url;
                uploading = false;
              });
            } catch (e) {
              setModal(() => uploading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: kRed,
                  ),
                );
              }
            }
          }

          Future<void> save() async {
            if (name.text.trim().isEmpty) return;
            if (double.tryParse(price.text) == null) return;
            try {
              await Api.post('/menu', {
                'name': name.text.trim(),
                'price': double.parse(price.text),
                'category':
                    category.text.trim().isEmpty ? null : category.text.trim(),
                'description':
                    desc.text.trim().isEmpty ? null : desc.text.trim(),
                'imageUrl': imageUrl,
              });
              if (mounted) Navigator.pop(ctx);
              await _load();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: kRed,
                  ),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New menu item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: uploading ? null : pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: kGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: uploading
                          ? const Center(
                              child: CircularProgressIndicator(color: kRed),
                            )
                          : imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: Api.url(imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: kRed, size: 36),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to add a photo',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Price (e.g. 5.99)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(
                      hintText: 'Category (e.g. Main, Drink)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: desc,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: save,
                    child: const Text('Save item'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------- CREATE RESTAURANT --------------------
  Widget _createRestaurantPrompt() {
    final auth = context.read<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 72, color: kRed),
              const SizedBox(height: 16),
              const Text(
                'No restaurant yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your restaurant to start listing meals and receiving orders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateRestaurant,
                  icon: const Icon(Icons.add),
                  label: const Text('Create restaurant'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateRestaurant() {
    final name = TextEditingController();
    final address = TextEditingController();
    final desc = TextEditingController();
    final phone = TextEditingController();
    String? imageUrl;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final xfile =
                  await picker.pickImage(source: ImageSource.gallery);
              if (xfile == null) return;
              setModal(() => uploading = true);
              final bytes = await xfile.readAsBytes();
              final url = await Api.uploadImageBytes(bytes, xfile.name);
              setModal(() {
                imageUrl = url;
                uploading = false;
              });
            } catch (e) {
              setModal(() => uploading = false);
            }
          }

          Future<void> save() async {
            if (name.text.trim().isEmpty) return;
            try {
              await Api.post('/restaurants', {
                'name': name.text.trim(),
                'address': address.text.trim(),
                'description': desc.text.trim(),
                'phone': phone.text.trim(),
                'imageUrl': imageUrl,
              });
              if (mounted) Navigator.pop(ctx);
              await _load();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: kRed,
                  ),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create your restaurant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: uploading ? null : pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: kGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: uploading
                          ? const Center(
                              child: CircularProgressIndicator(color: kRed),
                            )
                          : imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: Api.url(imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: kRed, size: 36),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to add a cover photo',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(hintText: 'Restaurant name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(hintText: 'Address'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(hintText: 'Phone (optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: desc,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Short description',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: save,
                    child: const Text('Create restaurant'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------- OWNER CHATS TAB --------------------
class _OwnerChatsTab extends StatefulWidget {
  const _OwnerChatsTab();

  @override
  State<_OwnerChatsTab> createState() => _OwnerChatsTabState();
}

class _OwnerChatsTabState extends State<_OwnerChatsTab> {
  List<dynamic> _convs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/chat/conversations');
      setState(() => _convs = r as List);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _convs.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: kBorder),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No customer chats yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _convs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _convs[i];
                      final msgs = c['messages'] as List?;
                      final last = (msgs != null && msgs.isNotEmpty)
                          ? msgs[0]['text']
                          : 'New conversation';
                      final customerName =
                          c['customer']?['name'] ?? 'Customer';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kRed.withValues(alpha: 0.15),
                            child: Text(
                              customerName.isNotEmpty
                                  ? customerName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: kRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            last.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.black26,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: c['id'],
                                restaurantName: customerName,
                              ),
                            ),
                          ).then((_) => _load()),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}