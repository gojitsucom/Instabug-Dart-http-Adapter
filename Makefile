SHELL := /bin/bash

generate:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

publish:
	fvm dart pub publish