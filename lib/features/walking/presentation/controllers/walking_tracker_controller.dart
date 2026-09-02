import 'dart:async';

import 'package:caloris/features/walking/domain/walking_filter_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class WalkingTrackerState {
  const WalkingTrackerState({
    this.isTracking = false,
    this.isWalking = false,
    this.isVehicleFiltered = false,
    this.steps = 0,
    this.estimatedCalories = 0,
    this.speedKmh = 0,
    this.elapsed = Duration.zero,
    this.message,
  });

  final bool isTracking;
  final bool isWalking;
  final bool isVehicleFiltered;
  final int steps;
  final double estimatedCalories;
  final double speedKmh;
  final Duration elapsed;
  final String? message;

  WalkingTrackerState copyWith({
    bool? isTracking,
    bool? isWalking,
    bool? isVehicleFiltered,
    int? steps,
    double? estimatedCalories,
    double? speedKmh,
    Duration? elapsed,
    String? message,
    bool clearMessage = false,
  }) => WalkingTrackerState(
    isTracking: isTracking ?? this.isTracking,
    isWalking: isWalking ?? this.isWalking,
    isVehicleFiltered: isVehicleFiltered ?? this.isVehicleFiltered,
    steps: steps ?? this.steps,
    estimatedCalories: estimatedCalories ?? this.estimatedCalories,
    speedKmh: speedKmh ?? this.speedKmh,
    elapsed: elapsed ?? this.elapsed,
    message: clearMessage ? null : message ?? this.message,
  );
}

final walkingTrackerControllerProvider =
    NotifierProvider<WalkingTrackerController, WalkingTrackerState>(
      WalkingTrackerController.new,
    );

class WalkingTrackerController extends Notifier<WalkingTrackerState> {
  static const _filter = WalkingFilterService();

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  WalkingFilterState _filterState = const WalkingFilterState();
  bool _pedestrianWalking = false;
  double _speedMetersPerSecond = 0;
  bool _locationReliable = true;
  double _weightKg = 70;
  DateTime? _startedAt;

  @override
  WalkingTrackerState build() {
    ref.onDispose(_cancelSubscriptions);
    return const WalkingTrackerState();
  }

  Future<void> start({required double weightKg}) async {
    if (state.isTracking) return;
    state = state.copyWith(clearMessage: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(
          message: 'Aktifkan layanan lokasi untuk memfilter kendaraan.',
        );
        return;
      }
      var locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
      }
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        state = state.copyWith(
          message: 'Izin lokasi diperlukan saat sesi jalan berlangsung.',
        );
        return;
      }
      final activityPermission = await Permission.activityRecognition.request();
      if (!activityPermission.isGranted) {
        state = state.copyWith(
          message: 'Izin aktivitas fisik diperlukan untuk menghitung langkah.',
        );
        return;
      }

      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _speedMetersPerSecond = initialPosition.speed < 0
          ? 0
          : initialPosition.speed;
      _locationReliable = true;
      _weightKg = weightKg > 0 ? weightKg : 70;
      _filterState = const WalkingFilterState();
      _startedAt = DateTime.now();
      state = const WalkingTrackerState(isTracking: true);

      _pedestrianSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onSensorError,
      );
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onSensorError,
      );
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onPosition, onError: _onLocationError);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final startedAt = _startedAt;
        if (startedAt != null && state.isTracking) {
          state = state.copyWith(elapsed: DateTime.now().difference(startedAt));
        }
      });
    } on TimeoutException {
      state = state.copyWith(
        message: 'Lokasi belum ditemukan. Coba di area yang lebih terbuka.',
      );
    } on Object {
      state = state.copyWith(
        message: 'Pelacakan belum dapat dimulai pada perangkat ini.',
      );
    }
  }

  Future<void> stop() async {
    if (!state.isTracking) return;
    await _cancelSubscriptions();
    state = state.copyWith(
      isTracking: false,
      isWalking: false,
      isVehicleFiltered: false,
      message: 'Sesi jalan dihentikan. Total sesi tetap ditampilkan.',
    );
  }

  void reset() {
    if (state.isTracking) return;
    _filterState = const WalkingFilterState();
    state = const WalkingTrackerState();
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _pedestrianWalking = event.status == 'walking';
    _publishMotionState();
  }

  void _onStepCount(StepCount event) {
    _filterState = _filter.acceptStepEvent(
      _filterState,
      rawSteps: event.steps,
      pedestrianWalking: _pedestrianWalking,
      speedMetersPerSecond: _locationReliable
          ? _speedMetersPerSecond
          : WalkingFilterService.maximumWalkingSpeedMetersPerSecond + 1,
    );
    state = state.copyWith(
      steps: _filterState.acceptedSteps,
      estimatedCalories: _filter.estimatedCalories(
        steps: _filterState.acceptedSteps,
        weightKg: _weightKg,
      ),
    );
  }

  void _onPosition(Position position) {
    _speedMetersPerSecond = position.speed < 0 ? 0 : position.speed;
    _locationReliable = true;
    _publishMotionState();
  }

  void _publishMotionState() {
    final vehicleFiltered =
        !_locationReliable ||
        _speedMetersPerSecond >
            WalkingFilterService.maximumWalkingSpeedMetersPerSecond;
    state = state.copyWith(
      isWalking: _pedestrianWalking && !vehicleFiltered,
      isVehicleFiltered: vehicleFiltered,
      speedKmh: _speedMetersPerSecond * 3.6,
    );
  }

  void _onSensorError(Object _) {
    state = state.copyWith(
      message: 'Sensor langkah tidak tersedia atau izinnya belum aktif.',
    );
  }

  void _onLocationError(Object _) {
    state = state.copyWith(
      message: 'Sinyal lokasi terputus; langkah dijeda agar kendaraan tidak terhitung.',
    );
    _locationReliable = false;
    _speedMetersPerSecond = 0;
    _publishMotionState();
  }

  Future<void> _cancelSubscriptions() async {
    _timer?.cancel();
    _timer = null;
    await _stepSubscription?.cancel();
    await _pedestrianSubscription?.cancel();
    await _positionSubscription?.cancel();
    _stepSubscription = null;
    _pedestrianSubscription = null;
    _positionSubscription = null;
    _startedAt = null;
  }
}
