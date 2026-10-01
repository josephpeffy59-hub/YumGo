import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../api.dart';
import '../../state/auth.dart';
import '../../theme.dart';

class CustomerChatsScreen extends StatefulWidget {
  const CustomerChatsScreen({super.key});

  @override
  State<CustomerChatsScreen> createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends State<CustomerChatsScreen> {
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
                          'No conversations yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Open a restaurant and tap Chat to start.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
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
                      final last =
                          (msgs != null && msgs.isNotEmpty) ? msgs[0]['text'] : 'Say hi';
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                const Icon(Icons.storefront, color: kRed),
                          ),
                          title: Text(
                            c['restaurant']?['name'] ?? 'Restaurant',
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
                                restaurantName:
                                    c['restaurant']?['name'] ?? 'Chat',
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

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? restaurantId;
  final String restaurantName;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final List<dynamic> _messages = [];
  IO.Socket? _socket;
  String? _convId;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.conversationId != null) {
        _convId = widget.conversationId;
      } else if (widget.restaurantId != null) {
        final c = await Api.post('/chat/conversation', {
          'restaurantId': widget.restaurantId,
        });
        _convId = c['id'];
      }

      if (_convId != null) {
        final list = await Api.get('/chat/$_convId/messages');
        _messages.addAll(list as List);
      }

      _socket = IO.io(
        Api.base,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      _socket!.connect();

      _socket!.onConnect((_) {
        if (_convId != null) _socket!.emit('join', _convId);
      });

      _socket!.on('message', (data) {
        if (!mounted) return;
        if (data is Map && data['conversationId'] == _convId) {
          setState(() => _messages.add(data));
          _scrollDown();
        }
      });
    } catch (e) {
      _err = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollDown();
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty || _convId == null || _socket == null) return;
    final me = context.read<AuthState>().user!;
    _socket!.emit('message', {
      'conversationId': _convId,
      'senderId': me['id'],
      'text': t,
    });
    _text.clear();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthState>().user?['id'];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurantName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Text(
              'YumGo chat',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : _err != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_err!, style: const TextStyle(color: kRed)),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet — say hi!',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) {
                                final m = _messages[i];
                                final senderId = m['senderId'] ??
                                    m['sender']?['id'];
                                final mine = senderId == myId;
                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.72,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine ? kRed : kGrey,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft:
                                            Radius.circular(mine ? 16 : 4),
                                        bottomRight:
                                            Radius.circular(mine ? 4 : 16),
                                      ),
                                    ),
                                    child: Text(
                                      m['text'] ?? '',
                                      style: TextStyle(
                                        color:
                                            mine ? kWhite : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 8,
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom + 8,
                      ),
                      decoration: const BoxDecoration(
                        color: kWhite,
                        border: Border(top: BorderSide(color: kBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _text,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: kRed,
                            radius: 22,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: kWhite,
                                size: 20,
                              ),
                              onPressed: _send,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}