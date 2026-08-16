/// Indonesia Western Time (WIB / Asia/Jakarta) = UTC+07:00, no daylight saving.
///
/// The Supabase database stores `created_at` as UTC. The app must therefore:
///  - send UTC boundaries (with `Z`) when querying by day, and
///  - convert stored UTC timestamps to WIB before displaying them.
library;

class WibTime {
  WibTime._();

  /// WIB offset from UTC.
  static const Duration offset = Duration(hours: 7);

  /// Convert a UTC instant (e.g. parsed from the DB `created_at`) to WIB.
  static DateTime toWib(DateTime utc) => utc.toUtc().add(offset);

  /// The current time expressed in WIB.
  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// Convert a WIB date/time (naive local components that the machine treats
  /// as WIB) to its UTC instant, suitable for `created_at` range queries.
  static DateTime toUtc(DateTime wib) => wib.toUtc();
}
