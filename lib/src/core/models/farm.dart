/// Data model for a hydroponic farm displayed on the map.
class Farm {
  final String id;
  final String name;
  final String product;
  final double rating;
  final int reviewCount;
  final int unitsInStock;
  final double pricePerKg;
  final double latitude;
  final double longitude;

  const Farm({
    required this.id,
    required this.name,
    required this.product,
    required this.rating,
    required this.reviewCount,
    required this.unitsInStock,
    required this.pricePerKg,
    required this.latitude,
    required this.longitude,
  });
}
