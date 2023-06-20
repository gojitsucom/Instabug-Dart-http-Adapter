SHELL := /bin/bash

generate:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

publish:
	PUB_HOSTED_URL=http://nexus.axlehire.com:7777 dart pub publish