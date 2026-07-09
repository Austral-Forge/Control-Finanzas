/// Catálogo de instituciones financieras y casas comerciales (Chile) que el
/// usuario puede vincular para medir los ingresos y gastos asociados a cada una.
enum InstitutionType { banco, casaComercial }

class Institution {
  final String key;
  final String name;
  final InstitutionType type;

  const Institution({
    required this.key,
    required this.name,
    required this.type,
  });
}

class InstitutionCatalog {
  static const String bancoDbValue = 'banco';
  static const String casaComercialDbValue = 'casa_comercial';

  static const List<Institution> all = [
    // --- Bancos ---
    Institution(key: 'banco_chile', name: 'Banco de Chile', type: InstitutionType.banco),
    Institution(key: 'banco_estado', name: 'BancoEstado', type: InstitutionType.banco),
    Institution(key: 'santander', name: 'Banco Santander', type: InstitutionType.banco),
    Institution(key: 'bci', name: 'BCI', type: InstitutionType.banco),
    Institution(key: 'scotiabank', name: 'Scotiabank', type: InstitutionType.banco),
    Institution(key: 'itau', name: 'Banco Itaú', type: InstitutionType.banco),
    Institution(key: 'banco_falabella', name: 'Banco Falabella', type: InstitutionType.banco),
    Institution(key: 'banco_ripley', name: 'Banco Ripley', type: InstitutionType.banco),
    Institution(key: 'tenpo', name: 'Tenpo', type: InstitutionType.banco),
    Institution(key: 'mach', name: 'MACH', type: InstitutionType.banco),
    Institution(key: 'mercado_pago', name: 'Mercado Pago', type: InstitutionType.banco),
    // --- Casas comerciales ---
    Institution(key: 'cmr_falabella', name: 'CMR Falabella', type: InstitutionType.casaComercial),
    Institution(key: 'ripley', name: 'Tarjeta Ripley', type: InstitutionType.casaComercial),
    Institution(key: 'cencosud', name: 'Cencosud Scotiabank', type: InstitutionType.casaComercial),
    Institution(key: 'hites', name: 'Hites', type: InstitutionType.casaComercial),
    Institution(key: 'la_polar', name: 'La Polar', type: InstitutionType.casaComercial),
    Institution(key: 'abcdin', name: 'abcdin', type: InstitutionType.casaComercial),
    Institution(key: 'tricot', name: 'Tricot', type: InstitutionType.casaComercial),
    Institution(key: 'lider_bci', name: 'Lider BCI', type: InstitutionType.casaComercial),
  ];

  static List<Institution> byType(InstitutionType type) =>
      all.where((i) => i.type == type).toList();

  static Institution? byKey(String key) {
    for (final institution in all) {
      if (institution.key == key) return institution;
    }
    return null;
  }

  static String typeDisplayName(InstitutionType type) {
    switch (type) {
      case InstitutionType.banco:
        return 'Bancos';
      case InstitutionType.casaComercial:
        return 'Casas Comerciales';
    }
  }

  static String typeToDb(InstitutionType type) =>
      type == InstitutionType.banco ? bancoDbValue : casaComercialDbValue;
}
