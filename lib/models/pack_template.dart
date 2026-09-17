import 'pack_list.dart';

class PackTemplate {
  const PackTemplate({
    required this.id,
    required this.name,
    required this.tripType,
    required this.proOnly,
    required this.description,
  });

  final String id;
  final String name;
  final TripType tripType;
  final bool proOnly;
  final String description;
}
