import 'package:flutter/material.dart';
import '../../api.dart';
import '../../theme.dart';

class ReviewsScreen extends StatefulWidget {
  final String restaurantId;
  const ReviewsScreen({super.key, required this.restaurantId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _loading = true;
  bool _posting = false;
  int _myRating = 5;
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/reviews/restaurant/${widget.restaurantId}');
      setState(() => _reviews = r as List);
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

  Future<void> _post() async {
    setState(() => _posting = true);
    try {
      await Api.post('/reviews', {
        'restaurantId': widget.restaurantId,
        'rating': _myRating,
        'comment': _comment.text.trim(),
      });
      _comment.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review posted!'),
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
      if (mounted) setState(() => _posting = false);
    }
  }

  double get _avg => _reviews.isEmpty
      ? 0
      : _reviews.fold<int>(0, (s, r) => s + (r['rating'] as int)) /
          _reviews.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            _avg.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: kRed,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < _avg.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: kRed,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leave a review',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < _myRating ? Icons.star : Icons.star_border,
                        color: kRed,
                      ),
                      onPressed: () => setState(() => _myRating = i + 1),
                    ),
                  ),
                ),
                TextField(
                  controller: _comment,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _posting ? null : _post,
                    child: _posting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: kWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Post review'),
                  ),
                ),
                const Divider(height: 40),
                if (_reviews.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No reviews yet. Be the first!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ..._reviews.map((r) => _reviewCard(r)),
              ],
            ),
    );
  }

  Widget _reviewCard(dynamic r) {
    final name = r['customer']?['name'] as String? ?? 'User';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: kRed.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: kRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (r['rating'] as int)
                                ? Icons.star
                                : Icons.star_border,
                            color: kRed,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (r['comment'] != null) ...[
              const SizedBox(height: 10),
              Text(r['comment']),
            ],
          ],
        ),
      ),
    );
  }
}