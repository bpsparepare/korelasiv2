import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthUtils {
  static Future<List<DateTime>> fetchMonthRange(SupabaseClient supabase) async {
    final response = await supabase
        .from('mv_korelasi_available_months')
        .select('month_start')
        .order('month_start');
    final monthDates = <DateTime>[];
    for (var item in (response as List)) {
      monthDates.add(DateTime.parse(item['month_start']));
    }
    if (monthDates.isEmpty) return [];
    monthDates.sort((a, b) => a.compareTo(b));
    final start = DateTime(monthDates.first.year, monthDates.first.month, 1);
    final current = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final last = DateTime(monthDates.last.year, monthDates.last.month, 1);
    final end = last.isBefore(current) ? current : last;
    final generated = <DateTime>[];
    var cursor = end;
    while (!cursor.isBefore(start)) {
      generated.add(cursor);
      cursor =
          cursor.month == 1
              ? DateTime(cursor.year - 1, 12, 1)
              : DateTime(cursor.year, cursor.month - 1, 1);
    }
    return generated;
  }

  static List<String> formatMonthsId(List<DateTime> months) {
    return months
        .map((d) => DateFormat('MMMM yyyy', 'id_ID').format(d))
        .toList();
  }
}
