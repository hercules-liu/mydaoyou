import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class FootprintPage extends StatefulWidget {
  const FootprintPage({super.key});

  @override
  State<FootprintPage> createState() => _FootprintPageState();
}

class _FootprintPageState extends State<FootprintPage> {
  List<Footprint> _footprints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFootprints();
  }

  Future<void> _loadFootprints() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _footprints = [
        Footprint(
          spotId: 'spot_001',
          spotName: '故宫',
          visitedAt: DateTime.now().subtract(const Duration(hours: 2)),
          hasPlayed: true,
        ),
        Footprint(
          spotId: 'spot_002',
          spotName: '天安门广场',
          visitedAt: DateTime.now().subtract(const Duration(hours: 1)),
          hasPlayed: true,
        ),
        Footprint(
          spotId: 'spot_003',
          spotName: '景山公园',
          visitedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          hasPlayed: false,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的足迹'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFootprintList(),
    );
  }

  Widget _buildFootprintList() {
    if (_footprints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tour, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无足迹',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              '开始探索附近景点吧',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _footprints.length,
            itemBuilder: (context, index) {
              return _buildFootprintItem(_footprints[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalSpots = _footprints.length;
    final playedSpots = _footprints.where((f) => f.hasPlayed).length;
    final totalTime = _footprints.length * 45;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('景点', '$totalSpots', Icons.location_on),
          _buildSummaryItem('已讲解', '$playedSpots', Icons.check_circle),
          _buildSummaryItem('时长', '${totalTime}分钟', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFootprintItem(Footprint footprint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: footprint.hasPlayed ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            footprint.hasPlayed ? Icons.check_circle : Icons.play_circle,
            color: footprint.hasPlayed ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          footprint.spotName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          _formatTime(footprint.visitedAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
        onTap: () {},
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}