import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    this.currencyCode = 'INR',
    this.taxRate = 0,
    this.serviceChargeRate = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String currencyCode;
  final double taxRate;
  final double serviceChargeRate;
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, name, currencyCode, taxRate, serviceChargeRate, isActive];
}
