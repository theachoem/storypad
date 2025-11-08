// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_deal_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProductDealObjectCWProxy {
  ProductDealObject product(AppProduct product);

  ProductDealObject discountPercentage(int discountPercentage);

  ProductDealObject endDate(DateTime endDate);

  ProductDealObject startDate(DateTime startDate);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ProductDealObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProductDealObject(...).copyWith(id: 12, name: "My name")
  /// ```
  ProductDealObject call({
    AppProduct product,
    int discountPercentage,
    DateTime endDate,
    DateTime startDate,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProductDealObject.copyWith(...)` or call `instanceOfProductDealObject.copyWith.fieldName(value)` for a single field.
class _$ProductDealObjectCWProxyImpl implements _$ProductDealObjectCWProxy {
  const _$ProductDealObjectCWProxyImpl(this._value);

  final ProductDealObject _value;

  @override
  ProductDealObject product(AppProduct product) => call(product: product);

  @override
  ProductDealObject discountPercentage(int discountPercentage) =>
      call(discountPercentage: discountPercentage);

  @override
  ProductDealObject endDate(DateTime endDate) => call(endDate: endDate);

  @override
  ProductDealObject startDate(DateTime startDate) => call(startDate: startDate);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ProductDealObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProductDealObject(...).copyWith(id: 12, name: "My name")
  /// ```
  ProductDealObject call({
    Object? product = const $CopyWithPlaceholder(),
    Object? discountPercentage = const $CopyWithPlaceholder(),
    Object? endDate = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
  }) {
    return ProductDealObject(
      product: product == const $CopyWithPlaceholder() || product == null
          ? _value.product
          // ignore: cast_nullable_to_non_nullable
          : product as AppProduct,
      discountPercentage:
          discountPercentage == const $CopyWithPlaceholder() ||
              discountPercentage == null
          ? _value.discountPercentage
          // ignore: cast_nullable_to_non_nullable
          : discountPercentage as int,
      endDate: endDate == const $CopyWithPlaceholder() || endDate == null
          ? _value.endDate
          // ignore: cast_nullable_to_non_nullable
          : endDate as DateTime,
      startDate: startDate == const $CopyWithPlaceholder() || startDate == null
          ? _value.startDate
          // ignore: cast_nullable_to_non_nullable
          : startDate as DateTime,
    );
  }
}

extension $ProductDealObjectCopyWith on ProductDealObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProductDealObject.copyWith(...)` or `instanceOfProductDealObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProductDealObjectCWProxy get copyWith =>
      _$ProductDealObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDealObject _$ProductDealObjectFromJson(Map<String, dynamic> json) =>
    ProductDealObject(
      product: $enumDecode(_$AppProductEnumMap, json['product']),
      discountPercentage: (json['discount_percentage'] as num).toInt(),
      endDate: ProductDealObject._fromJsonToLocal(json['end_date'] as String),
      startDate: ProductDealObject._fromJsonToLocal(
        json['start_date'] as String,
      ),
    );

Map<String, dynamic> _$ProductDealObjectToJson(ProductDealObject instance) =>
    <String, dynamic>{
      'product': _$AppProductEnumMap[instance.product]!,
      'discount_percentage': instance.discountPercentage,
      'start_date': ProductDealObject._toJsonUtc(instance.startDate),
      'end_date': ProductDealObject._toJsonUtc(instance.endDate),
    };

const _$AppProductEnumMap = {
  AppProduct.voice_journal: 'voice_journal',
  AppProduct.relax_sounds: 'relax_sounds',
  AppProduct.templates: 'templates',
  AppProduct.period_calendar: 'period_calendar',
};
