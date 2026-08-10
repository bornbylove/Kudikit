// lib/features/transfer/domain/entities/bank_entity.dart
//
// Was declared inline in bank_selection_bottom_sheet.dart. Moved here so the
// repository can return it without the domain layer importing a widget file.
//
// NOTE: this is a *second* Bank type — lib/model/bankmodel/bank_model.dart
// defines a richer one (id, ussdCode, isActive) used by wallet, bankdeposit
// and transaction. The two are not interchangeable and are populated from the
// same GET /banks endpoint. See the parsing discrepancy noted in
// TransferRepositoryImpl.getBanks. Consolidating them belongs with the
// lib/model/ migration.

class Bank {
  final String name;
  final String code;
  final String? logo;

  const Bank({
    required this.name,
    required this.code,
    this.logo,
  });

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        name: json['name'] as String,
        code: json['code'] as String,
        logo: json['logo'] as String?,
      );
}
