import '../../data/models/transaction_item.dart';

abstract class FinanceEvent {}

class LoadFinanceSummaries extends FinanceEvent {}

class LoadMonthDetails extends FinanceEvent {
  final int year;
  final int month;

  LoadMonthDetails({required this.year, required this.month});
}

class AddTransaction extends FinanceEvent {
  final TransactionItem transaction;

  AddTransaction({required this.transaction});
}

class DeleteTransaction extends FinanceEvent {
  final int id;
  final int year;
  final int month;

  DeleteTransaction({
    required this.id,
    required this.year,
    required this.month,
  });
}
