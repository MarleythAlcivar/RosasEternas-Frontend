# Rosas Eternas — Frontend

Cliente móvil multiplataforma de **Rosas Eternas**, desarrollado con Flutter.

## Funciones

- Inicio de sesión y registro local para la demostración.
- Catálogo, detalle de producto, carrito y confirmación de pedidos.
- Ubicación aproximada y cámara solicitadas solamente al momento de uso.
- Comunicación con la API FastAPI mediante `API_BASE_URL`.

## Requisitos y ejecución

1. Instale Flutter estable y Android Studio.
2. Ejecute `flutter pub get`.
3. Con la API activa, ejecute en una tablet por USB:

```powershell
adb -s <ID_TABLET> reverse tcp:800 tcp:800
flutter run -d <ID_TABLET> --dart-define=API_BASE_URL=http://127.0.0.1:800
```

Para emulador Android use `http://10.0.2.2:800` como URL base. No almacene contraseñas, tokens ni claves en este repositorio.

## Backend relacionado

El código de la API se publica por separado en el repositorio **RosasEternas-Backend**.
