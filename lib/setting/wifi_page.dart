import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/wifi.dart';

class WiFiSettingsPage extends StatefulWidget {
  const WiFiSettingsPage({super.key});

  @override
  State<WiFiSettingsPage> createState() => _WiFiSettingsPageState();
}

class _WiFiSettingsPageState extends State<WiFiSettingsPage> {
  bool wifiEnabled = true;
  String? connectedSsid = 'ZTE-f6S6uY';

  final List<String> myNetworks = [
    'CMCC-tg5f',
  ];

  final List<String> otherNetworks = [
    'CMCC-m5kf',
    'Wireless_cn2',
  ];

  @override
  void initState() {
    super.initState();
    _loadStatusAndScan();
  }

  Future<void> _loadStatusAndScan() async {
    final st = await WiFiService.status();
    final list = await WiFiService.scan();
    setState(() {
      wifiEnabled = st['enabled'] == true;
      connectedSsid = (st['ssid'] as String?)?.isNotEmpty == true ? st['ssid'] as String : null;
      // 用扫描结果更新分组（简单合并示例）
      myNetworks.clear();
      otherNetworks.clear();
      for (final ap in list) {
        final ssid = ap['ssid'] as String? ?? '';
        if (ssid.isEmpty) continue;
        if (ssid == connectedSsid) continue;
        // 简单规则：包含 CMCC 归入“我的网络”，其他进“其他网络”
        if (ssid.startsWith('CMCC')) {
          myNetworks.add(ssid);
        } else {
          otherNetworks.add(ssid);
        }
      }
    });
  }

  Future<void> _toggleWifi(bool value) async {
    setState(() => wifiEnabled = value);
    final ok = await WiFiService.enable(value);
    if (!ok) {
      setState(() => wifiEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('切换 Wi‑Fi 失败')),
      );
      return;
    }
    await _loadStatusAndScan();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _section(List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList(),
        ),
      ),
    );
  }

  Widget _wifiIcon({bool enabled = true}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'source/app_ico/WLAN.svg',
        width: 28,
        height: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('无线局域网'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatusAndScan,
            tooltip: '刷新网络',
          ),
        ],
      ),
      body: ListView(
        children: [
          // 顶部说明卡片
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _wifiIcon(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '无线局域网',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '接入无线局域网，查看可用网络，并管理加入网络及附近热点设置',
                            style:
                                TextStyle(color: Colors.black54, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 开关行（使用 ListTile + trailing Switch，而不是 SwitchListTile）
          _section([
            ListTile(
              title: const Text('无线局域网'),
              trailing: Switch(
                value: wifiEnabled,
                onChanged: (v) => _toggleWifi(v),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 当前连接网络
          if (connectedSsid != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '已连接',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _section([
              ListTile(
                leading: const Icon(Icons.check, color: Colors.blue),
                title: Text(connectedSsid!),
                subtitle: const Text('已连接'),
                trailing: Wrap(
                  spacing: 12,
                  children: const [
                    Icon(Icons.lock_outline, size: 20, color: Colors.black54),
                    Icon(Icons.info_outline, size: 20, color: Colors.black54),
                  ],
                ),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
          ],

          _sectionHeader('我的网络'),
          _section(
            myNetworks
                .map(
                  (ssid) => ListTile(
                    title: Text(ssid),
                    trailing: const Icon(Icons.info_outline,
                        size: 20, color: Colors.black54),
                    onTap: () {},
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 24),

          _sectionHeader('其他网络'),
          _section(
            otherNetworks
                .map(
                  (ssid) => ListTile(
                    title: Text(ssid),
                    trailing: Wrap(
                      spacing: 12,
                      children: const [
                        Icon(Icons.lock_outline,
                            size: 20, color: Colors.black54),
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.black54),
                      ],
                    ),
                    onTap: () {},
                  ),
                )
                .toList()
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
