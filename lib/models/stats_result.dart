class StatsResult {
  final double totalGeneral;
  final Map<String, double> totalPorCuartel;
  final Map<String, double> totalPorDia;

  StatsResult({
    required this.totalGeneral,
    required this.totalPorCuartel,
    required this.totalPorDia,
  });
}
