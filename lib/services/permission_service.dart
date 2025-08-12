import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Uygulama izinlerini yöneten servis
class PermissionService {
  /// Bildirim izni iste
  /// 
  /// Bu metot kullanıcıdan bildirim izni ister.
  /// Doğrudan sistem izin isteği gösterilir, ekstra dialog gösterilmez.
  Future<bool> requestNotificationPermission() async {
    // Android 13 (API 33) ve üzeri için bildirim izni gerekli
    // Android 12 ve altı için bildirim izni otomatik olarak verilir
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true; // İzin zaten verilmiş
    }
    
    // İzin iste - doğrudan sistem dialogu gösterilir
    final result = await Permission.notification.request();
    
    // İzin sonucunu kontrol et ve dön
    return result.isGranted;
  }

  
  /// Uygulama ayarlarını aç
  Future<void> openApplicationSettings() async {
    await openAppSettings();
  }

  /// İzin durumunu kontrol et ve kullanıcıya bilgi ver
  Future<bool> checkAndRequestPermission(Permission permission, BuildContext context, String permissionName) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await permission.request();
      if (result.isGranted) {
        return true;
      } else {
        if (context.mounted) {
          _showPermissionDeniedMessage(context, permissionName);
        }
        return false;
      }
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context, permissionName);
      }
      return false;
    }
    
    return false;
  }

  /// İzin reddedildiğinde mesaj göster
  void _showPermissionDeniedMessage(BuildContext context, String permissionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$permissionName izni gerekli. Lütfen ayarlardan izni açın.'),
        action: SnackBarAction(
          label: 'Ayarlar',
          onPressed: () => openApplicationSettings(),
        ),
      ),
    );
  }

  /// İzin kalıcı olarak reddedildiğinde dialog göster
  void _showPermissionPermanentlyDeniedDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('İzin Gerekli'),
          content: Text('$permissionName kullanabilmek için ayarlardan izni manuel olarak açmanız gerekiyor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openApplicationSettings();
              },
              child: Text('Ayarlar'),
            ),
          ],
        );
      },
    );
  }
}
