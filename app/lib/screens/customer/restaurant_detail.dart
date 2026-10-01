import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api.dart';
import '../../theme.dart';
import 'reviews.dart';
import 'chats.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Map<String, dynamic>? _restaurant;
  bool _loading = true;
  bool _placing = false;
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/restaurants/${widget.id}');
      setState(() => _restaurant = r);
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

  double get _cartTotal {
    if (_restaurant == null) return 0;
    final items = List<Map<String, dynamic>>.from(
      _restaurant!['menuItems'] ?? [],
    );
    return items.fold(
      0.0,
      (s, m) => s + (m['price'] as num) * (_cart[m['id']] ?? 0),
    );
  }

  int get _cartCount => _cart.values.fold(0, (s, v) => s + v);

  void _add(String id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1);

  void _remove(String id) {
    setState(() {
      final q = (_cart[id] ?? 0) - 1;
      if (q <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = q;
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _placing = true);
    try {
      final items = _cart.entries
          .map((e) => {'menuItemId': e.key, 'quantity': e.value})
          .toList();
      await Api.post('/orders', {
        'restaurantId': widget.id,
        'items': items,
      });
      if (!mounted) return;
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed! Check the Orders tab.'),
          backgroundColor: kRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }
    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: const Center(child: Text('Restaurant not found')),
      );
    }

    final r = _restaurant!;
    final menu = List<Map<String, dynamic>>.from(r['menuItems'] ?? []);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in menu) {
      final cat = (m['category'] as String?)?.trim().isNotEmpty == true
          ? m['category'] as String
          : 'Menu';
      grouped.putIfAbsent(cat, () => []).add(m);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kWhite,
            foregroundColor: kRed,
            flexibleSpace: FlexibleSpaceBar(
              background: r['imageUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: Api.url(r['imageUrl']),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: kGrey,
                        child: const Icon(
                          Icons.restaurant,
                          color: kRed,
                          size: 64,
                        ),
                      ),
                    )
                  : Container(
                      color: kGrey,
                      child: const Icon(
                        Icons.restaurant,
                        color: kRed,
                        size: 64,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: kRed, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        ((r['avgRating'] ?? 0) as num).toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      if (r['address'] != null)
                        Expanded(
                          child: Text(
                            r['address'],
                            style: const TextStyle(color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (r['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      r['description'],
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                     OutlinedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        restaurantId: r['id'],
        restaurantName: r['name'],
      ),
    ),
  ),
  icon: const Icon(Icons.chat_bubble_outline),
  label: const Text('Chat'),
),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReviewsScreen(restaurantId: r['id']),
    ),
  ),
  icon: const Icon(Icons.rate_review_outlined),
  label: const Text('Reviews'),
),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    color: kRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final m = entry.value[i];
                  final qty = _cart[m['id']] ?? 0;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (m['imageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: Api.url(m['imageUrl']),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: kGrey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fastfood, color: kRed),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (m['description'] != null)
                                    Text(
                                      m['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${(m['price'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: kRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            qty == 0
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: kRed,
                                      size: 30,
                                    ),
                                    onPressed: () => _add(m['id']),
                                  )
                                : Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: kRed,
                                        ),
                                        onPressed: () => _remove(m['id']),
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: kRed,
                                        ),
                                        onPressed: () => _add(m['id']),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: entry.value.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomSheet: _cartCount == 0
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: kWhite,
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartCount item${_cartCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '\$${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _placing ? null : _placeOrder,
                        child: _placing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: kWhite,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Place order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}