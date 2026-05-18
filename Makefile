DOCS_DIR := docs

.PHONY: docs docs-build docs-serve docs-clean

docs: docs-serve

docs-serve: _require-node
	@port=8080; \
	max=8999; \
	while [ "$$port" -le "$$max" ]; do \
		if ! lsof -i :$$port -sTCP:LISTEN >/dev/null 2>&1; then \
			break; \
		fi; \
		port=$$((port + 1)); \
	done; \
	if [ "$$port" -gt "$$max" ]; then \
		echo "error: no free HTTP port between 8080 and $$max"; \
		exit 1; \
	fi; \
	wsport=3001; \
	wsmax=3999; \
	while [ "$$wsport" -le "$$wsmax" ]; do \
		if ! lsof -i :$$wsport -sTCP:LISTEN >/dev/null 2>&1; then \
			break; \
		fi; \
		wsport=$$((wsport + 1)); \
	done; \
	if [ "$$wsport" -gt "$$wsmax" ]; then \
		echo "error: no free WebSocket port between 3001 and $$wsmax (needed for hot reload)"; \
		exit 1; \
	fi; \
	printf 'quartz: http://localhost:%s (hot reload ws: %s)\n' "$$port" "$$wsport"; \
	ulimit -n 8192 >/dev/null 2>&1 || true; \
	cd $(DOCS_DIR) && pnpm quartz build --serve --port "$$port" --wsPort "$$wsport"

docs-build: _require-node
	cd $(DOCS_DIR) && pnpm quartz build

docs-clean:
	rm -rf $(DOCS_DIR)/public $(DOCS_DIR)/.quartz-cache $(DOCS_DIR)/book

_require-node:
	@command -v node >/dev/null 2>&1 || { echo "error: node not found. Install Node.js 22+"; exit 127; }
	@command -v pnpm >/dev/null 2>&1 || { echo "error: pnpm not found. Install pnpm"; exit 127; }
	@test -d $(DOCS_DIR)/node_modules || { echo "error: run 'cd $(DOCS_DIR) && pnpm install' first"; exit 1; }
