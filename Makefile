generate:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

publish:
	fvm flutter pub publish

format:
	fvm flutter format lib test
