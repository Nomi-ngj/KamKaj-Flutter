/// Dependency-free date formatting matching the design ("October 2, 2026").
abstract final class DateFormatter {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String long(DateTime date) => '${_months[date.month - 1]} ${date.day}, ${date.year}';
}
