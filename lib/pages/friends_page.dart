import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/location_service.dart';
import '../models/friend.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FriendService _friendService = FriendService();
  final LocationService _locationService = LocationService();

  List<Friend> _friends = [];
  bool _isLoading = true;
  Map<String, double>? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _friendService.init();
    final location = await _locationService.getCurrentPosition();
    final friends = await _friendService.getFriends();

    setState(() {
      _friends = friends;
      _userLocation = location;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同伴位置'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无好友',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '添加好友后可以查看同伴位置',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('添加好友'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              return _buildFriendCard(_friends[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '您的位置',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
                Text(
                  _userLocation != null
                      ? '${_userLocation!['latitude']?.toStringAsFixed(4)}, ${_userLocation!['longitude']?.toStringAsFixed(4)}'
                      : '正在获取位置...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_userLocation == null)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    final distance = _userLocation != null
        ? _friendService.getDistanceToFriend(
            friend,
            _userLocation!['latitude']!,
            _userLocation!['longitude']!,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(friend.avatar),
                  onBackgroundImageError: (_, __) {},
                ),
                if (friend.currentLocation != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              friend.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Row(
              children: [
                Icon(
                  friend.currentLocation != null
                      ? Icons.location_on
                      : Icons.location_off,
                  size: 14,
                  color: friend.currentLocation != null
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  friend.currentLocation != null
                      ? friend.lastUpdateText
                      : '位置未知',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              color: Theme.of(context).primaryColor,
              onPressed: () => _navigateToFriend(friend),
            ),
          ),
          if (distance != null)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '步行 ${_estimateWalkingTime(distance)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}米';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}公里';
    }
  }

  String _estimateWalkingTime(double meters) {
    final minutes = (meters / 80).round();
    if (minutes < 1) return '<1分钟';
    if (minutes < 60) return '${minutes}分钟';
    return '${(minutes / 60).toStringAsFixed(1)}小时';
  }

  void _navigateToFriend(Friend friend) {
    if (friend.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法导航：好友位置未知')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在规划前往 ${friend.name} 的路线...'),
        action: SnackBarAction(
          label: '查看地图',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加好友'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '好友ID或手机号',
            hintText: '请输入',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final friend = await _friendService.addFriend(
                  'new_user',
                  controller.text,
                );
                setState(() {
                  _friends.add(friend);
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}