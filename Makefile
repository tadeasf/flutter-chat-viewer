.PHONY: install-linux test analyze

# Rebuild the release bundle and reinstall it for the current user.
install-linux:
	scripts/install-linux.sh

test:
	flutter test

analyze:
	flutter analyze
