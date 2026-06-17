.DEFAULT_GOAL := default

include site.mk

SOURCE_FILES=lib/**/*.dart
TEST_FILES=test/**/*.dart

DOC_DIR=doc
COVERAGE_DIR=coverage
ADDLICENSE_CONFIG=addlicense_config.txt

# BEGIN: Primary tasks

default: clean prepare license_check format analyze test doc_site
.PHONY: all

cicd: default
.PHONY: cicd

pre_commit: license_check test
.PHONY: pre_commit

# END: Primary tasks

test:
	dart test
.PHONY: test

format:
	dart format lib/ test/ example/
.PHONY: format

analyze:
	dart analyze
.PHONY: analyze

coverage: coverage.log
.PHONY: coverage

coverage.log: lib/** test/**
	# flutter test --coverage
	dart test --coverage-path=coverage/lcov.info
	rm -rf $(SITE_DIR)/coverage
	mkdir -p $(SITE_DIR)/coverage
	genhtml coverage/lcov.info \
		--legend \
		-o $(SITE_DIR)/coverage

license_check:
	@echo "Checking for license headers..."
	cat $(ADDLICENSE_CONFIG) | xargs addlicense --check

license_add:
	cat $(ADDLICENSE_CONFIG) | xargs addlicense

doc:
	dart doc --output=$(DOC_DIR) --validate-links .
.PHONY: doc

prepare:
	dart pub global activate coverage
	dart pub get
.PHONY: prepare

clean:
	rm -rf $(DOC_DIR)
	rm -rf $(COVERAGE_DIR)
	rm -rf site
.PHONY: clean
