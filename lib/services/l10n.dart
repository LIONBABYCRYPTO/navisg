import 'package:shared_preferences/shared_preferences.dart';

/// Simple Chinese localization for the Navisg app.
/// Key: English string → Chinese translation.
class L10n {
  static const String _prefKey = 'navisg_locale';

  /// Whether Chinese mode is enabled
  static Future<bool> isChinese() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) == 'zh';
  }

  /// Toggle Chinese mode
  static Future<void> setChinese(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, enabled ? 'zh' : 'en');
  }

  /// Translate a string. Pass `chinese` as the current preference value.
  /// Falls back to English when no translation exists.
  static String tr(Map<String, String> map, {required bool chinese}) {
    if (!chinese) return map['en'] ?? '';
    return map['zh'] ?? map['en'] ?? '';
  }
}

/// App-level localization strings
class AppStrings {
  static Map<String, String> get navisg => {'en': 'Nāvisg', 'zh': '畅行狮城'};
  static Map<String, String> get saved => {'en': 'Saved', 'zh': '收藏'};
  static Map<String, String> get nearby => {'en': 'Nearby', 'zh': '附近'};
  static Map<String, String> get map => {'en': 'Map', 'zh': '地图'};
  static Map<String, String> get carpark => {'en': 'Carpark', 'zh': '停车场'};
  static Map<String, String> get mrt => {'en': 'MRT', 'zh': '地铁'};
  static Map<String, String> get traffic => {'en': 'Traffic', 'zh': '交通'};
  static Map<String, String> get settings => {'en': 'Settings', 'zh': '设置'};
  static Map<String, String> get search => {'en': 'Search', 'zh': '搜索'};
  static Map<String, String> get refresh => {'en': 'Refresh', 'zh': '刷新'};
  static Map<String, String> get darkMode => {'en': 'Dark Mode', 'zh': '深色模式'};
  static Map<String, String> get language => {'en': 'Language', 'zh': '语言'};
  static Map<String, String> get chinese => {'en': '中文', 'zh': '中文'};
  static Map<String, String> get english => {'en': 'English', 'zh': 'English'};
  static Map<String, String> get version => {'en': 'Version', 'zh': '版本'};
  static Map<String, String> get noSavedStops => {
    'en': 'No Saved Stops Yet',
    'zh': '还没有收藏的车站',
  };
  static Map<String, String> get findStopsHint => {
    'en': 'Tap search to find and save your favorite bus stops.',
    'zh': '点击搜索查找并收藏您的常用巴士站。',
  };
  static Map<String, String> get findStops => {
    'en': 'Find Bus Stops',
    'zh': '查找巴士站',
  };
  static Map<String, String> get loading => {
    'en': 'Loading Navisg...',
    'zh': '正在加载...',
  };
  static Map<String, String> get justNow => {
    'en': 'just now',
    'zh': '刚刚',
  };
  static Map<String, String> get minAgo => {
    'en': 'min ago',
    'zh': '分钟前',
  };
  static Map<String, String> get updated => {
    'en': 'Updated',
    'zh': '更新于',
  };
  static Map<String, String> get filterStops => {
    'en': 'Filter stops...',
    'zh': '筛选车站...',
  };
  static Map<String, String> get share => {
    'en': 'Share',
    'zh': '分享',
  };
  static Map<String, String> get allClear => {
    'en': 'All clear on the roads!',
    'zh': '道路畅通！',
  };
  static Map<String, String> get noIncidents => {
    'en': 'No incidents reported',
    'zh': '暂无事故报告',
  };
  static Map<String, String> get searchByCodeName => {
    'en': 'Search by stop code or name...',
    'zh': '按车站编号或名称搜索...',
  };
  static Map<String, String> get about => {
    'en': 'About',
    'zh': '关于',
  };
  static Map<String, String> get madeWith => {
    'en': 'Made with ❤️ for SG commuters',
    'zh': '用心为新加坡通勤者打造',
  };
  static Map<String, String> get autoRefresh => {
    'en': 'Auto-refresh',
    'zh': '自动刷新',
  };
  static Map<String, String> get direction => {
    'en': 'Direction',
    'zh': '方向',
  };
  static Map<String, String> get allDirection => {
    'en': 'All',
    'zh': '全部',
  };
  static Map<String, String> get busRoute => {
    'en': 'Bus Route',
    'zh': '巴士路线',
  };
  static Map<String, String> get reportTiming => {
    'en': 'Report Inaccurate Timing',
    'zh': '报告不准确的巴士时间',
  };
  static Map<String, String> get rateApp => {
    'en': 'Rate on Play Store',
    'zh': '在应用商店评分',
  };
  static Map<String, String> get shareApp => {
    'en': 'Share App',
    'zh': '分享应用',
  };
  static Map<String, String> get checkUpdate => {
    'en': 'Check for Updates',
    'zh': '检查更新',
  };
  static Map<String, String> get nearbyMap => {
    'en': 'Nearby Map',
    'zh': '附近地图',
  };
  static Map<String, String> get myLocation => {
    'en': 'Your Location',
    'zh': '我的位置',
  };
  static Map<String, String> get nearbyStops => {
    'en': 'Nearby Stops',
    'zh': '附近车站',
  };
  static Map<String, String> get locateMe => {
    'en': 'Locate Me',
    'zh': '定位我',
  };
  static Map<String, String> get savedRoutes => {
    'en': 'Saved Routes',
    'zh': '已保存路线',
  };
  static Map<String, String> get feedback => {
    'en': 'Feedback & Support',
    'zh': '反馈与支持',
  };
  static Map<String, String> get updates => {
    'en': 'Updates',
    'zh': '更新',
  };
  static Map<String, String> get openSource => {
    'en': 'Open Source',
    'zh': '开源代码',
  };
}
