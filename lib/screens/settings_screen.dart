import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lta_service.dart';
import '../services/l10n.dart';
import '../models/bus_stop.dart';

/// Settings screen — theme toggle, API key, language, about
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

          _SectionHeader(title: _chinese ? '数据' : 'Data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.key),
              title: Text(_chinese ? 'LTA API密钥' : 'LTA API Key'),
              subtitle: Text(_chinese ? '更新您的DataMall密钥' : 'Update your DataMall key'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showApiKeyDialog(context),
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: _chinese ? '关于' : 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(_chinese ? '版本' : 'Version'),
                  subtitle: const Text('1.1.0+1'),
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
