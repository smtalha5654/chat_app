import 'package:intl/intl.dart';

String formatMessageTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final isToday =
      local.year == now.year && local.month == now.month && local.day == now.day;
  if (isToday) {
    return DateFormat.Hm().format(local);
  }
  return DateFormat('MMM d, HH:mm').format(local);
}
