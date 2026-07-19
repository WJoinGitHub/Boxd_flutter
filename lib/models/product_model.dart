/// 支持的产品（GET /api/v1/products）
class ProductModel {
  final String productCode;
  final String productName;
  final String productType;
  final String model;
  final String appDisplayName;
  final String bleBroadcastName;
  final String homeImageUrl;
  final String connectImageUrl;

  const ProductModel({
    required this.productCode,
    required this.productName,
    required this.productType,
    required this.model,
    required this.appDisplayName,
    required this.bleBroadcastName,
    required this.homeImageUrl,
    required this.connectImageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productCode: json['product_code']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productType: json['product_type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      appDisplayName: json['app_display_name']?.toString() ?? '',
      bleBroadcastName: json['ble_broadcast_name']?.toString() ?? '',
      homeImageUrl: json['home_image_url']?.toString() ?? '',
      connectImageUrl: json['connect_image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product_code': productCode,
        'product_name': productName,
        'product_type': productType,
        'model': model,
        'app_display_name': appDisplayName,
        'ble_broadcast_name': bleBroadcastName,
        'home_image_url': homeImageUrl,
        'connect_image_url': connectImageUrl,
      };
}
