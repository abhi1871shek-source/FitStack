import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'telemetry_provider.dart';

class StepCountNotifier extends Notifier<int> {
  @override
  int build() {
    final telemetry = ref.watch(todayTelemetryProvider);
    return telemetry?.stepCount ?? 6240;
  }

  void setSteps(int steps) {
    final clamped = steps.clamp(0, 100000);
    state = clamped;
    ref.read(telemetryNotifierProvider.notifier).updateSteps(clamped);
  }
}

final stepCountProvider = NotifierProvider<StepCountNotifier, int>(() {
  return StepCountNotifier();
});
