/// 기간 내 복약 순응도
class AdherenceSummary {
  const AdherenceSummary({required this.taken, required this.total});

  final int taken;
  final int total;

  /// 0.0 ~ 1.0. 예정된 복용이 없으면 null
  double? get rate => total == 0 ? null : taken / total;
}
