import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:purchases_flutter/models/store_product_wrapper.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/types/app_product.dart';

part 'product_deal_object.g.dart';

@CopyWith()
@JsonSerializable()
class ProductDealObject {
  final AppProduct product;
  final int discountPercentage;

  @JsonKey(fromJson: _fromJsonToLocal, toJson: _toJsonUtc)
  final DateTime startDate;

  @JsonKey(fromJson: _fromJsonToLocal, toJson: _toJsonUtc)
  final DateTime endDate;

  ProductDealObject({
    required this.product,
    required this.discountPercentage,
    required this.endDate,
    required this.startDate,
  });

  bool get active {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  ({String displayPrice, String displayComparePrice})? getDisplayPrice(StoreProduct storeProduct) {
    if (!active) return null;

    final discountedPrice = storeProduct.price;
    final convertedToOriginalPrice = discountedPrice / (1 - discountPercentage / 100);

    return (
      displayPrice: '${discountedPrice.toStringAsFixed(2)} ${storeProduct.currencyCode}',
      displayComparePrice: '${convertedToOriginalPrice.toStringAsFixed(2)} ${storeProduct.currencyCode}',
    );
  }

  static Map<AppProduct, ProductDealObject> getActiveDeals() {
    // return getMockActiveDealsByEndDate(DateTime.now().add(const Duration(days: 10)));

    Map<dynamic, dynamic> json = RemoteConfigService.productDeals.get();
    final dealsJson = json['deals'];

    Map<AppProduct, ProductDealObject> deals = {};

    if (dealsJson is List) {
      for (dynamic dealJson in dealsJson) {
        if (dealJson is Map<String, dynamic>) {
          try {
            final deal = ProductDealObject.fromJson(dealJson);
            if (deal.active) deals[deal.product] = deal;
          } catch (e) {
            AppLogger.error('ProductDealObject.getThings failed to parse product deal: $e');
          }
        }
      }
    }

    return deals;
  }

  static DateTime _fromJsonToLocal(String date) => DateTime.parse(date).toLocal();
  static String _toJsonUtc(DateTime date) => date.toUtc().toIso8601String();

  factory ProductDealObject.fromJson(Map<String, dynamic> json) => _$ProductDealObjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDealObjectToJson(this);

  @Deprecated('Test only')
  static Map<AppProduct, ProductDealObject> getMockActiveDealsByEndDate(DateTime mockEndDate) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 1));

    final mockDeals = <AppProduct, ProductDealObject>{
      AppProduct.voice_journal: ProductDealObject(
        product: AppProduct.voice_journal,
        discountPercentage: 30,
        startDate: startDate,
        endDate: mockEndDate,
      ),
      AppProduct.templates: ProductDealObject(
        product: AppProduct.templates,
        discountPercentage: 40,
        startDate: startDate,
        endDate: mockEndDate,
      ),
    };

    return mockDeals;
  }
}
