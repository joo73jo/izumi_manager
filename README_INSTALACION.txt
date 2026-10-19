IZUMI MANAGER - ETAPA 6

1. Detener flutter run en PowerShell presionando q.
2. Descomprimir este ZIP en D:\izumi_app, ACEPTANDO combinar carpetas
   y reemplazar lib\main.dart.
3. Abrir D:\izumi_app\pubspec.yaml y agregar justo debajo de
   flutter: en la sección flutter: (NO en dependencies):

flutter:
  uses-material-design: true
  assets:
    - assets/images/izumi_logo.png

Nota: la sección flutter: ya existe, solo agrega la clave assets:
con indentación de dos espacios y su entrada de cuatro espacios.
4. Ejecutar desde D:\izumi_app:
   flutter pub get
   flutter run -d windows

Esto NO incluye pubspec.yaml para preservar el proyecto actual.
