import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/avoid_dublicated_call_service.dart';

// Tracks how often each template is used by a device.
// Note: A malicious user could fake usage by spoofing device IDs,
// but this is acceptable since the data is only used for analytics.
class GalleryTemplateUsageService {
  GalleryTemplateUsageService._();
  static GalleryTemplateUsageService get instance => GalleryTemplateUsageService._();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  final avoidDublicatedCallService = AvoidDublicatedCallService();

  Future<void> recordTemplateUsage({
    required String templateId,
  }) async {
    return avoidDublicatedCallService.run(() async {
      final docRef = firestore.collection('templates').doc(templateId).collection('devices').doc(kDeviceInfo.id);

      bool exist = await docRef.get().then((e) => e.exists);
      if (exist) {
        await docRef.update({
          'last_used_at': FieldValue.serverTimestamp(),
          'usage_count': FieldValue.increment(1),
        });
      } else {
        Map<String, Object> data = {
          'device_id': kDeviceInfo.id,
          'last_used_at': FieldValue.serverTimestamp(),
          'usage_count': 1,
          'first_used_at': FieldValue.serverTimestamp(),
          'model': kDeviceInfo.model,
        };
        await docRef.set(data);
      }
    });
  }
}
