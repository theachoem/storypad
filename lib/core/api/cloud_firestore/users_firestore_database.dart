import 'package:spooky/core/api/cloud_firestore/base_cloud_firestore.dart';
import 'package:spooky/core/models/base_model.dart';
import 'package:spooky/core/models/purchased_info_model.dart';

class UsersFirestoreDatabase extends BaseCloudFirestore {
  @override
  String get collectionName => "users";

  @override
  BaseModel objectTransformer(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  Future<void> addProduct(
    String productId,
    String uid,
    PurchasedInfoModel info,
  ) async {
    final productsRef = reference.doc(uid).collection('products');
    await productsRef.doc(productId).set({
      'purchase_id': info.purchaseId,
    });
  }

  Future<List<String>> fetchPurchasedProducts(String uid) async {
    final productsRef = reference.doc(uid).collection('products');
    final result = await productsRef.get();

    List<String> purchases = [];
    for (final doc in result.docs) {
      final info = doc.data();
      bool? premium = info['premium'];
      if (info['purchase_id'] != null || premium == true) {
        purchases.add(doc.id);
      }
    }

    return purchases;
  }
}
