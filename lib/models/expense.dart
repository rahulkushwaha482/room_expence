class Expense {
  String id;
  String item;
  double amount;
  String paidBy;
  String date;
  final List<String> sharedBetween;

  Expense({
    required this.id,
    required this.item,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.sharedBetween,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      item: json['item'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      sharedBetween: json['sharedBetween'] != null
          ? List<String>.from(json['sharedBetween'])
          : [json['paid_by']], // fallback: only paidBy
      date: json['date'] as String,
    );
  }


  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'amount': amount,
        'paid_by': paidBy,
        'date': date,
        'sharedBetween': sharedBetween,
      };
}
