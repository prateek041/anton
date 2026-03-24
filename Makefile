MDBOOK := mdbook
DOCS_DIR := docs

.PHONY: docs docs-build docs-serve docs-clean docs-watch

# Default: open dev server with live reload
docs: docs-serve

docs-build: _require-mdbook
	$(MDBOOK) build $(DOCS_DIR)

docs-serve: _require-mdbook
	$(MDBOOK) serve $(DOCS_DIR) --open

docs-clean: _require-mdbook
	$(MDBOOK) clean $(DOCS_DIR)

docs-watch: _require-mdbook
	$(MDBOOK) watch $(DOCS_DIR)

_require-mdbook:
	@command -v $(MDBOOK) >/dev/null 2>&1 || { \
		echo "error: mdbook is not installed or not on PATH."; \
		echo "  Arch: sudo pacman -S mdbook"; \
		echo "  Or:   cargo install mdbook"; \
		exit 127; \
	}
