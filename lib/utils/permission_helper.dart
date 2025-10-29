import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> ensureGalleryPermission(BuildContext context) async {
    // desktop/web: consentito
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) {
        await _showSettingsDialog(context, 'Galleria');
      }
      return false;
    }

    // Android 13+: photos -> READ_MEDIA_IMAGES
    var aStatus = await Permission.photos.status;
    if (aStatus.isGranted) return true;
    aStatus = await Permission.photos.request();
    if (aStatus.isGranted) return true;
    if (aStatus.isPermanentlyDenied) {
      await _showSettingsDialog(context, 'Galleria');
    }
    return false;
  }

  static Future<bool> ensureCameraPermission(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false; // camera non gestita qui

    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context, 'Fotocamera');
    }
    return false;
  }

  static Future<void> _showSettingsDialog(BuildContext context, String perm) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permesso richiesto'),
        content: Text('Per usare $perm, abilita il permesso nelle Impostazioni.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Apri Impostazioni'),
          ),
        ],
      ),
    );
  }
}
