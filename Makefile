generate:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

publish:
	PUB_HOSTED_URL=http://pub.dev fvm flutter pub publish

format:
	fvm flutter format lib test
