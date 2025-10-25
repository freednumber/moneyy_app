import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> ensureGalleryPermission(BuildContext context) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      final req = await Permission.photos.request();
      if (req.isGranted || req.isLimited) return true;
      if (req.isPermanentlyDenied) {
        await _showSettingsDialog(context, 'Galleria');
      }
      return false;
    }
    if (Platform.isAndroid) {
      final status = await Permission.photos.status; // READ_MEDIA_IMAGES su Android 13+
      if (status.isGranted) return true;
      final req = await Permission.photos.request();
      if (req.isGranted) return true;
      if (req.isPermanentlyDenied) {
        await _showSettingsDialog(context, 'Galleria');
      }
      return false;
    }
    return true; // desktop/web
  }

  static Future<bool> ensureCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final req = await Permission.camera.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
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
