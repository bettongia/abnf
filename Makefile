.DEFAULT_GOAL := default

SOURCE_FILES=lib/**/*.dart
TEST_FILES=test/**/*.dart

DOC_DIR=doc
COVERAGE_DIR=coverage
ADDLICENSE_CONFIG=addlicense_config.txt

# BEGIN: Primary tasks

default: clean prepare license_check format analyze test coverage doc
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

coverage:
	dart run coverage:test_with_coverage --out $(COVERAGE_DIR)
	genhtml $(COVERAGE_DIR)/lcov.info -o $(COVERAGE_DIR)/html
.PHONY: coverage

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
.PHONY: clean
