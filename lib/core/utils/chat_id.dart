String chatIdFor(String userIdA, String userIdB) {
  final ids = [userIdA, userIdB]..sort();
  return '${ids[0]}_${ids[1]}';
}
