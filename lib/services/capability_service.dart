import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/delivery_context.dart';

class CapabilityResult {
  const CapabilityResult(this.state, {this.value, this.message});
  final CapabilityState state;
  final String? value;
  final String? message;
}

class CapabilityService {
  CapabilityService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<CapabilityResult> requestDeliveryLocation() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const CapabilityResult(CapabilityState.unavailable);
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const CapabilityResult(CapabilityState.serviceDisabled);
    }
    var permission = await Permission.locationWhenInUse.status;
    if (permission.isDenied) {
      permission = await Permission.locationWhenInUse.request();
    }
    final state = _permissionState(permission);
    if (state != CapabilityState.granted) {
      return CapabilityResult(state);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      // Approximate location only: three decimals reduce unnecessary precision.
      final latitude = position.latitude.toStringAsFixed(3);
      final longitude = position.longitude.toStringAsFixed(3);
      return CapabilityResult(
        CapabilityState.granted,
        value: 'Referencia aproximada: $latitude, $longitude',
      );
    } on LocationServiceDisabledException {
      return const CapabilityResult(CapabilityState.serviceDisabled);
    } catch (_) {
      return const CapabilityResult(
        CapabilityState.failed,
        message:
            'No se pudo obtener la ubicación. Puedes escribir tu dirección.',
      );
    }
  }

  Future<CapabilityResult> requestReferencePhoto() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const CapabilityResult(CapabilityState.unavailable);
    }
    var permission = await Permission.camera.status;
    if (permission.isDenied) {
      permission = await Permission.camera.request();
    }
    final state = _permissionState(permission);
    if (state != CapabilityState.granted) {
      return CapabilityResult(state);
    }
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (image == null) {
        return const CapabilityResult(
          CapabilityState.granted,
          message:
              'No seleccionaste una foto. Puedes continuar sin adjuntarla.',
        );
      }
      final directory = await getApplicationDocumentsDirectory();
      final destination = File(
        '${directory.path}${Platform.pathSeparator}referencia_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(image.path).copy(destination.path);
      return CapabilityResult(CapabilityState.granted, value: destination.path);
    } catch (_) {
      return const CapabilityResult(
        CapabilityState.failed,
        message: 'No se pudo guardar la foto. Puedes continuar sin adjuntarla.',
      );
    }
  }

  CapabilityState _permissionState(PermissionStatus permission) {
    if (permission.isGranted || permission.isLimited) {
      return CapabilityState.granted;
    }
    if (permission.isPermanentlyDenied) {
      return CapabilityState.permanentlyDenied;
    }
    if (permission.isRestricted) {
      return CapabilityState.restricted;
    }
    return CapabilityState.denied;
  }
}
