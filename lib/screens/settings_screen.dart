import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/lta_service.dart';
import '../services/l10n.dart';
import '../models/bus_stop.dart';

/// Settings screen — theme, language, feedback, share, update check, about.
class SettingsScreen extends StatefulWidget {
  final LTAService ltaService;
  final List<BusStop> allStops;

  const SettingsScreen({
    super.key,
    required this.ltaService,
    required this.allStops,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _chinese = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _chinese = prefs.getString('navisg_locale') == 'zh';
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _darkMode = value);
  }

  Future<void> _toggleChinese(bool value) async {
    await L10n.setChinese(value);
    setState(() => _chinese = value);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_chinese ? '无法打开链接' : 'Could not open link')),
        );
      }
    }
  }

  void _shareApp() {
    final text = _chinese
        ? '🚌 试试 Nāvisg — 新加坡实时公交、地铁、停车场、交通信息！\nhttps://play.google.com/store/apps/details?id=com.navisg.navisg'
        : '🚌 Check out Nāvisg — real-time SG bus arrivals, MRT, carpark & traffic!\nhttps://play.google.com/store/apps/details?id=com.navisg.navisg';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_chinese ? '应用链接已复制！分享给朋友吧 🎉' : 'App link copied! Share with friends 🎉'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_chinese ? '设置' : 'Settings'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === APPEARANCE ===
          _SectionHeader(title: _chinese ? '外观' : 'Appearance'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                _darkMode ? Icons.dark_mode : Icons.light_mode,
                color: _darkMode ? Colors.amber : Colors.orange,
              ),
              title: Text(_chinese ? '深色模式' : 'Dark Mode'),
              subtitle: Text(
                _darkMode
                    ? (_chinese ? '已启用深色主题' : 'Dark theme enabled')
                    : (_chinese ? '已启用浅色主题' : 'Light theme enabled'),
              ),
              value: _darkMode,
              onChanged: _toggleDarkMode,
            ),
          ),

          const SizedBox(height: 24),

          // === LANGUAGE ===
          _SectionHeader(title: _chinese ? '语言' : 'Language'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.language, color: Colors.blue),
              title: Text(_chinese ? '中文' : 'Chinese (中文)'),
              subtitle: Text(
                _chinese ? '界面切换为中文' : 'Switch UI to Chinese',
              ),
              value: _chinese,
              onChanged: _toggleChinese,
            ),
          ),

          const SizedBox(height: 24),

          // === FEEDBACK & SUPPORT ===
          _SectionHeader(title: _chinese ? '反馈与支持' : 'Feedback & Support'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.report_problem, color: Colors.orange),
                  title: Text(_chinese ? '报告不准确的巴士时间' : 'Report Inaccurate Timing'),
                  subtitle: Text(
                    _chinese ? '帮助我们改善数据准确性' : 'Help us improve data accuracy',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(
                    'mailto:navisg.app@gmail.com?subject=${_chinese ? "巴士时间不准确报告" : "Bus Timing Inaccuracy Report"}',
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(_chinese ? '在应用商店评分' : 'Rate on Play Store'),
                  subtitle: Text(
                    _chinese ? '您的评价帮助我们成长' : 'Your rating helps us grow',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(
                    'https://play.google.com/store/apps/details?id=com.navisg.navisg',
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: Text(_chinese ? '分享应用给朋友' : 'Share App'),
                  subtitle: Text(
                    _chinese ? '推荐 Nāvisg 给好友和家人' : 'Recommend Nāvisg to friends & family',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.share, size: 18),
                  onTap: _shareApp,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // === UPDATE ===
          _SectionHeader(title: _chinese ? '更新' : 'Updates'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update, color: Colors.green),
              title: Text(_chinese ? '检查更新' : 'Check for Updates'),
              subtitle: Text(
                _chinese ? '前往 Play Store 获取最新版本' : 'Visit Play Store for the latest version',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launchUrl(
                'https://play.google.com/store/apps/details?id=com.navisg.navisg',
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === DATA ===
          _SectionHeader(title: _chinese ? '数据' : 'Data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.key),
              title: Text(_chinese ? 'LTA API密钥' : 'LTA API Key'),
              subtitle: Text(
                _chinese ? '更新您的DataMall密钥' : 'Update your DataMall key',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showApiKeyDialog(context),
            ),
          ),

          const SizedBox(height: 24),

          // === ABOUT ===
          _SectionHeader(title: _chinese ? '关于' : 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(_chinese ? '版本' : 'Version'),
                  subtitle: const Text('1.2.0+1'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(Icons.map),
                  title: Text('Map Data'),
                  subtitle: Text('© OpenStreetMap contributors'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(Icons.directions_bus),
                  title: Text('Transport Data'),
                  subtitle: Text('LTA DataMall'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.grey),
                  title: Text(
                    _chinese ? '开源代码' : 'Open Source',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  subtitle: Text(
                    _chinese ? '在 GitHub 上查看源代码' : 'View source on GitHub',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                  onTap: () => _launchUrl('https://github.com/LIONBABYCRYPTO/navisg'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              _chinese ? '畅行狮城 — 新加坡出行助手' : 'Nāvisg — Navigate Singapore',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _chinese ? '用心为新加坡通勤者打造 ❤️' : 'Made with ❤️ for SG commuters',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_chinese ? '更新API密钥' : 'Update API Key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _chinese ? 'LTA DataMall AccountKey' : 'LTA DataMall AccountKey',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_chinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('lta_api_key', controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _chinese ? 'API密钥已更新，请重启应用' : 'API key updated. Restart app to apply.',
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(_chinese ? '保存' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
