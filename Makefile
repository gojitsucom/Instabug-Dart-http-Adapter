publish:
	PUB_HOSTED_URL=http://nexus.axlehire.com:7777 dart pub publish

format:
	fvm flutter format lib

slang_run:
	npx --yes json-sort-cli assets/i18n/translations.i18n.json && fvm flutter pub run slang && fvm flutter format lib/i18n/translations.g.dart

upload_i18n:
	axl i18n upload -p .

download_i18n:
	axl i18n download -p .