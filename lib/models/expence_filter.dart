class ExpenseFilter {
  final String? paidBy;
  final List<String>? membersIncluded; // members in sharedBetween
  final DateTime? fromDate;
  final DateTime? toDate;

  ExpenseFilter({this.paidBy, this.membersIncluded, this.fromDate, this.toDate});
}
