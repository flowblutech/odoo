# ==================================================================================== #
## ===== HELPERS =====
# ==================================================================================== #
## help: Describe all the targets
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## all: call the help
.PHONY: all
all: help
# ==================================================================================== #

# ==================================================================================== #
## ===== MAIN COMMANDS =====
# ==================================================================================== #
rebuild:
	@START=$$(date +%s); \
	echo 'Starting rebuild...'; \
	docker-compose -f docker-compose.yml down; \
	echo 'Removing build caches...'; \
	docker builder prune -a; \
	echo 'Removing Odoo image...'; \
	docker image prune --all; \
	echo 'Building odoo...'; \
	docker-compose -f docker-compose.yml up -d; \
	END=$$(date +%s); \
	ELAPSED=$$((END-START)); \
	echo "Finished rebuilding in $$((ELAPSED/3600))h $$(((ELAPSED%3600)/60))m $$((ELAPSED%60))s. Odoo is running"

restart:
	@START=$$(date +%s); \
	echo 'Starting restarting...'; \
	docker-compose -f docker-compose.yml down; \
	docker-compose -f docker-compose.yml up -d; \
	END=$$(date +%s); \
	ELAPSED=$$((END-START)); \
	echo "Finished restarting in $$((ELAPSED/3600))h $$(((ELAPSED%3600)/60))m $$((ELAPSED%60))s. Odoo is running"
