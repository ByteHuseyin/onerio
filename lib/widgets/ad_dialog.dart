import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/l10n/app_localizations.dart';
import 'package:oneiro/services/admob_service.dart';

class AdDialog extends StatefulWidget {
  final String characterName;
  final Function(String) onContinue;
  final VoidCallback? onCancel;

  const AdDialog({
    super.key,
    required this.characterName,
    required this.onContinue,
    this.onCancel,
  });

  @override
  State<AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<AdDialog> with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _pulseController;
  late Animation<double> _countdownAnimation;
  late Animation<double> _pulseAnimation;
  
  int _countdown = 3;
  bool _canSkip = false;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    
    // Countdown animasyonu
    _countdownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _countdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.linear,
    ));

    // Pulse animasyonu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startCountdown();
    _checkAdStatus();
  }

  void _startCountdown() {
    _countdownController.forward();
    _pulseController.repeat(reverse: true);
    
    // Her saniye countdown'u güncelle
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _canSkip = true;
            _pulseController.stop();
            // Countdown bittiğinde otomatik olarak reklamı göster
            if (_isAdReady) {
              Navigator.of(context).pop();
              _showRewardedAd();
            }
          }
        });
      }
      return _countdown > 0;
    });
  }

  void _checkAdStatus() {
    setState(() {
      _isAdReady = AdMobService().isRewardedAdReady;
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Text(
              AppLocalizations.of(context)!.adDialogTitle,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Mesaj
            Text(
              AppLocalizations.of(context)!.adDialogMessage,
              style: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Reklam durumu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isAdReady 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAdReady 
                    ? Colors.green.withOpacity(0.5)
                    : Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAdReady ? Icons.check_circle : Icons.schedule,
                    color: _isAdReady ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAdReady 
                      ? AppLocalizations.of(context)!.adReady
                      : AppLocalizations.of(context)!.adNotReady,
                    style: GoogleFonts.nunito(
                      color: _isAdReady ? Colors.green : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // İzle ve Öğren butonu (üstte)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _showRewardedAd();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: _isAdReady 
                    ? const Color(0xFF9D50BB)
                    : Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isAdReady ? 8 : 0,
                  shadowColor: _isAdReady 
                    ? Colors.purpleAccent.withOpacity(0.4)
                    : Colors.transparent,
                ),
                child: Text(
                  '${AppLocalizations.of(context)!.watchAndLearn} ($_countdown)',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Vazgeç butonu (altta)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onCancel != null) {
                    widget.onCancel!();
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: GoogleFonts.nunito(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    try {
      print('AdMob: Dialog\'dan reklam gösteriliyor...');
      
      bool rewardEarned = await AdMobService().showRewardedAd();
      
      if (rewardEarned) {
        print('AdMob: Kullanıcı ödül kazandı');
        _showSuccessMessage();
      } else {
        print('AdMob: Kullanıcı ödül kazanmadı');
      }
      
      // Reklam gösterildikten sonra karakter seçimini tamamla
      widget.onContinue(widget.characterName);
      
    } catch (e) {
      print('AdMob: Reklam gösterim hatası: $e');
      // Hata durumunda da karakter seçimini tamamla
      widget.onContinue(widget.characterName);
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.adRewardEarned,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF9D50BB),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
