/// Um serviço/procedimento oferecido pelo negócio (ex: "Manicure", 40.0)
class BusinessService {
  final String name;
  final double price;
  final bool   active;

  /// Aba "Clientes & Marketing": em quantos dias a cliente deve refazer
  /// este serviço. 0 = não lembra.
  final int returnDays;

  const BusinessService({required this.name, this.price = 0, this.active = true, this.returnDays = 0});

  factory BusinessService.fromJson(Map<String, dynamic> json) => BusinessService(
        name:       json['name'] ?? '',
        price:      (json['price'] ?? 0).toDouble(),
        active:     json['active'] ?? true,
        returnDays: json['returnDays'] is num ? (json['returnDays'] as num).toInt() : 0,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'price': price, 'active': active, 'returnDays': returnDays};

  BusinessService copyWith({String? name, double? price, bool? active, int? returnDays}) => BusinessService(
        name:       name ?? this.name,
        price:      price ?? this.price,
        active:     active ?? this.active,
        returnDays: returnDays ?? this.returnDays,
      );
}

/// Configuração completa de um negócio (tenant): identidade visual,
/// serviços oferecidos e locais de atendimento.
class BusinessConfig {
  final String businessName;
  final String ownerName; // nome do dono, para a saudação ("Bom dia, Ana!")
  final String logoUrl;
  final String primaryColor; // hex, ex: "#B47FD4"
  final List<BusinessService> services;
  final List<String> locations; // 1 ou 2
  final int workStart;
  final int workEnd;

  const BusinessConfig({
    this.businessName = '',
    this.ownerName = '',
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
        ownerName:    json['ownerName'] ?? '',
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
        'ownerName':    ownerName,
        'logoUrl':      logoUrl,
        'primaryColor': primaryColor,
        'services':     services.map((s) => s.toJson()).toList(),
        'locations':    locations,
        'workStart':    workStart,
        'workEnd':      workEnd,
      };

  BusinessConfig copyWith({
    String? businessName,
    String? ownerName,
    String? logoUrl,
    String? primaryColor,
    List<BusinessService>? services,
    List<String>? locations,
    int? workStart,
    int? workEnd,
  }) =>
      BusinessConfig(
        businessName: businessName ?? this.businessName,
        ownerName:    ownerName ?? this.ownerName,
        logoUrl:      logoUrl ?? this.logoUrl,
        primaryColor: primaryColor ?? this.primaryColor,
        services:     services ?? this.services,
        locations:    locations ?? this.locations,
        workStart:    workStart ?? this.workStart,
        workEnd:      workEnd ?? this.workEnd,
      );
}
