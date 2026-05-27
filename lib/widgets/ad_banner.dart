import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Real AdMob banner ad widget
/// Replace sampleAdUnitId with your real one in production
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  static const String _adUnitId = 'ca-app-pub-4594842929104765/8786404271';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
