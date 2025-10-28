.PHONY: help test test-unit test-widget test-integration test-golden coverage clean format analyze

help:
	@echo "Available commands:"
	@echo "  make test              - Run all tests"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-widget       - Run widget tests only"
	@echo "  make test-integration  - Run integration tests only"
	@echo "  make test-golden       - Run golden tests"
	@echo "  make coverage          - Generate and view coverage report"
	@echo "  make format            - Format all Dart files"
	@echo "  make analyze           - Run static analysis"
	@echo "  make clean             - Clean build artifacts"

test:
	flutter test

test-unit:
	flutter test test/unit/

test-widget:
	flutter test test/widget/

test-integration:
	flutter test test/integration/

test-golden:
	flutter test --update-goldens --tags=golden

coverage:
	flutter test --coverage
	@if command -v lcov > /dev/null; then \
		genhtml coverage/lcov.info -o coverage/html; \
		echo "Coverage report generated at coverage/html/index.html"; \
	else \
		echo "lcov not installed. Run: sudo apt-get install lcov"; \
	fi

format:
	dart format .

analyze:
	flutter analyze

clean:
	flutter clean
	rm -rf coverage/
