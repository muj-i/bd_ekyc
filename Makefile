VARIABLE1 := "Building Release APK" 

run:
	flutter run --release -t example/lib/main.dart

apk:
	flutter build apk --release -t example/lib/main.dart;

.PHONY: apk run