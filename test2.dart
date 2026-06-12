void main() {
  List<dynamic> list = [{'user': {'id': '1'}}];
  List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(list);
  String currentUserId = '2';
  try {
    final myMemberObj = members.firstWhere((m) => m['user']['id'] == currentUserId, orElse: () => null as Map<String, dynamic>);
    print('SUCCESS: $myMemberObj');
  } catch (e) {
    print('ERROR: $e');
  }
}
