/// Um serviço/procedimento oferecido pelo negócio (ex: "Manicure", 40.0)
class BusinessService {
  final String name;
  final double price;
  final bool   active;

  const BusinessService({required this.name, this.price = 0, this.active = true});

  factory BusinessService.fromJson(Map<String, dynamic> json) => BusinessService(
        name:   json['name'] ?? '',
        price:  (json['price'] ?? 0).toDouble(),
        active: json['active'] ?? true,
      );

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'active': active};

  BusinessService copyWith({String? name, double? price, bool? active}) => BusinessService(
        name:   name ?? this.name,
        price:  price ?? this.price,
        active: active ?? this.active,
      );
}

/// Configuração completa de um negócio (tenant): identidade visual,
/// serviços oferecidos e locais de atendimento.
class BusinessConfig {
  final String businessName;
  final String logoUrl;
  final String primaryColor; // hex, ex: "#B47FD4"
  final List<BusinessService> services;
  final List<String> locations; // 1 ou 2
  final int workStart;
  final int workEnd;

  const BusinessConfig({
    this.businessName = '',
    this.logoUrl = '',
    this.primaryColor = '#B47FD4',
    this.services = const [],
    this.locations = const [],
    this.workStart = 7,
    this.workEnd = 21,
  });

  /// true se o usuário ainda não configurou nada — precisa passar pelo onboarding
  bool get needsOnboarding => locations.isEmpty || services.isEmpty;

  factory BusinessConfig.fromJson(Map<String, dynamic> json) => BusinessConfig(
        businessName: json['businessName'] ?? '',
        logoUrl:      json['logoUrl'] ?? '',
        primaryColor: json['primaryColor'] ?? '#B47FD4',
        services: (json['services'] as List? ?? [])
            .map((s) => BusinessService.fromJson(s))
            .toList(),
        locations: List<String>.from(json['locations'] ?? const []),
        workStart: json['workStart'] ?? 7,
        workEnd:   json['workEnd'] ?? 21,
      );

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'logoUrl':      logoUrl,
        'primaryColor': primaryColor,
        'services':     services.map((s) => s.toJson()).toList(),
        'locations':    locations,
        'workStart':    workStart,
        'workEnd':      workEnd,
      };

  BusinessConfig copyWith({
    String? businessName,
    String? logoUrl,
    String? primaryColor,
    List<BusinessService>? services,
    List<String>? locations,
    int? workStart,
    int? workEnd,
  }) =>
      BusinessConfig(
        businessName: businessName ?? this.businessName,
        logoUrl:      logoUrl ?? this.logoUrl,
        primaryColor: primaryColor ?? this.primaryColor,
        services:     services ?? this.services,
        locations:    locations ?? this.locations,
        workStart:    workStart ?? this.workStart,
        workEnd:      workEnd ?? this.workEnd,
      );
}
