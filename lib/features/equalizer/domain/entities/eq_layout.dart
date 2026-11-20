import 'package:equatable/equatable.dart';

/// One band of the phone's equalizer, in hertz.
final class EqBand extends Equatable {
  final double lowHz;
  final double centerHz;
  final double highHz;

  const EqBand({
    required this.lowHz,
    required this.centerHz,
    required this.highHz,
  });

  @override
  List<Object?> get props => [lowHz, centerHz, highHz];
}

/// The bands the phone offers and the range of their gains. Nothing about
/// it is fixed: five bands is common, not certain, and so is ±15 dB.
final class EqLayout extends Equatable {
  /// Lowest band first.
  final List<EqBand> bands;
  final double minDb;
  final double maxDb;

  const EqLayout({
    required this.bands,
    required this.minDb,
    required this.maxDb,
  });

  /// [db] within the range, by half decibels: Android takes whole
  /// millibels, and a finer step is not heard.
  double fit(double db) => ((db * 2).round() / 2).clamp(minDb, maxDb);

  @override
  List<Object?> get props => [bands, minDb, maxDb];
}
