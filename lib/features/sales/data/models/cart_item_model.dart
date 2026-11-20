import '../../../products/data/models/product_model.dart';

/// Model untuk item keranjang belanja kasir.
class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({required this.product, this.quantity = 1});

  int get lineTotal => product.sellingPrice * quantity;
  int get lineCost => product.costPrice * quantity;

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
