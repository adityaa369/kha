void main() {
  DateTime start = DateTime(2026, 10, 2);
  DateTime due = DateTime(2026, 11, 2);
  int calc = (due.difference(start).inDays / 30).round();
  print(calc);
}
