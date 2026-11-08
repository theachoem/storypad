import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/avoid_dublicated_call_service.dart';
import 'package:storypad/core/storages/template_usage_install_id_storage.dart';

// Tracks how often each template is used per install, keyed by a random install ID
// ([TemplateUsageInstallIdStorage]) — not a hardware or advertising ID.
// Note: A malicious user could fake usage by spoofing install IDs,
// but this is acceptable since the data is only used for analytics.
class GalleryTemplateUsageService {
  GalleryTemplateUsageService._();
  static GalleryTemplateUsageService get instance => GalleryTemplateUsageService._();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  final avoidDublicatedCallService = AvoidDublicatedCallService();

  Future<void> recordTemplateUsage({
    required String templateId,
  }) async {
    if (!kFirebaseAvailable) return;

    try {
      return await avoidDublicatedCallService.run(() async {
        final installId = await TemplateUsageInstallIdStorage().readOrCreate();
        final docRef = firestore.collection('templates').doc(templateId).collection('devices').doc(installId);

        bool exist = await docRef.get().then((e) => e.exists);
        if (exist) {
          await docRef.update({
            'last_used_at': FieldValue.serverTimestamp(),
            'usage_count': FieldValue.increment(1),
          });
        } else {
          Map<String, Object> data = {
            'device_id': installId,
            'last_used_at': FieldValue.serverTimestamp(),
            'usage_count': 1,
            'first_used_at': FieldValue.serverTimestamp(),
            'model': kDeviceInfo.model,
          };
          await docRef.set(data);
        }
      });
    } catch (_) {
      // Usage tracking is best-effort analytics; ignore failures (e.g. offline/unavailable).
    }
  }
}
