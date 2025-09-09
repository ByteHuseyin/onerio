import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // AdMob ID'leri
  static const String _appId = 'ca-app-pub-7299067074949548~5714724354';
  static const String _rewardedAdUnitId = 'ca-app-pub-7299067074949548/3248343110';
  
  // Test ID'leri (debug modunda kullanılır)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // AdMob'u başlat
  static Future<void> initialize() async {
    print('AdMob: Başlatılıyor...');
    await MobileAds.instance.initialize();
    print('AdMob: Başarıyla başlatıldı');
    
    // Reklamları yükle
    await AdMobService().loadRewardedAd();
  }

  // Ödüllü reklam yükle
  Future<void> loadRewardedAd() async {
    print('AdMob: Ödüllü reklam yükleniyor...');
    
    final String adUnitId = kDebugMode ? _testRewardedAdUnitId : _rewardedAdUnitId;
    
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('AdMob: Ödüllü reklam başarıyla yüklendi');
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          // Reklam kapandığında yeniden yükle
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('AdMob: Ödüllü reklam kapatıldı, yeniden yükleniyor...');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('AdMob: Ödüllü reklam gösterim hatası: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('AdMob: Ödüllü reklam yükleme hatası: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  // Ödüllü reklam göster
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('AdMob: Ödüllü reklam hazır değil');
      return false;
    }

    print('AdMob: Ödüllü reklam gösteriliyor...');
    
    bool rewardEarned = false;
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('AdMob: Kullanıcı ödül kazandı: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );
    
    return rewardEarned;
  }

  // Reklam hazır mı kontrol et
  bool get isRewardedAdReady => _isRewardedAdReady;

  // Reklam durumunu kontrol et
  void checkAdStatus() {
    print('AdMob: Reklam durumu - Hazır: $_isRewardedAdReady');
  }
}
