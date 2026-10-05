enum CapabilityState {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
  unavailable,
  failed,
}

class DeliveryContext {
  const DeliveryContext({
    this.locationState = CapabilityState.notRequested,
    this.cameraState = CapabilityState.notRequested,
    this.locationLabel,
    this.photoPath,
    this.updatedAt,
    this.syncPending = false,
  });

  final CapabilityState locationState;
  final CapabilityState cameraState;
  final String? locationLabel;
  final String? photoPath;
  final DateTime? updatedAt;
  final bool syncPending;

  bool get hasPhoto => photoPath != null;

  DeliveryContext copyWith({
    CapabilityState? locationState,
    CapabilityState? cameraState,
    String? locationLabel,
    bool clearLocation = false,
    String? photoPath,
    bool clearPhoto = false,
    DateTime? updatedAt,
    bool? syncPending,
  }) => DeliveryContext(
    locationState: locationState ?? this.locationState,
    cameraState: cameraState ?? this.cameraState,
    locationLabel: clearLocation ? null : locationLabel ?? this.locationLabel,
    photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
    updatedAt: updatedAt ?? this.updatedAt,
    syncPending: syncPending ?? this.syncPending,
  );

  Map<String, dynamic> toJson() => {
    'locationState': locationState.name,
    'cameraState': cameraState.name,
    'locationLabel': locationLabel,
    'photoPath': photoPath,
    'updatedAt': updatedAt?.toIso8601String(),
    'syncPending': syncPending,
  };

  factory DeliveryContext.fromJson(Map<String, dynamic> json) =>
      DeliveryContext(
        locationState: _state(json['locationState']),
        cameraState: _state(json['cameraState']),
        locationLabel: json['locationLabel'] as String?,
        photoPath: json['photoPath'] as String?,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        syncPending: json['syncPending'] as bool? ?? false,
      );

  static CapabilityState _state(Object? value) =>
      CapabilityState.values
          .where((state) => state.name == value)
          .firstOrNull ??
      CapabilityState.notRequested;
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
