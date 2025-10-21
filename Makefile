# Dolibarr Docker Makefile
# Provides convenient commands for Docker operations

.PHONY: help build up down restart logs shell db-shell clean backup restore status

# Default target
help:
	@echo "Dolibarr Docker Management Commands:"
	@echo ""
	@echo "  make up              - Start all services"
	@echo "  make up-tools        - Start with optional tools (PHPMyAdmin, Maildev)"
	@echo "  make down            - Stop all services"
	@echo "  make restart         - Restart all services"
	@echo "  make build           - Build/rebuild Docker images"
	@echo "  make logs            - View application logs"
	@echo "  make logs-db         - View database logs"
	@echo "  make shell           - Open shell in Dolibarr container"
	@echo "  make db-shell        - Open MySQL shell"
	@echo "  make status          - Show container status"
	@echo "  make backup          - Backup database and files"
	@echo "  make clean           - Stop and remove all containers, volumes (CAUTION!)"
	@echo "  make reset           - Complete reset (removes all data!)"
	@echo ""

# Build Docker images
build:
	docker-compose build --no-cache

# Start services
up:
	docker-compose up -d
	@echo ""
	@echo "Dolibarr is starting..."
	@echo "Access at: http://localhost:8080"
	@echo "Default login: admin / admin123"
	@echo ""

# Start with optional tools
up-tools:
	docker-compose --profile tools up -d
	@echo ""
	@echo "Services started:"
	@echo "- Dolibarr: http://localhost:8080"
	@echo "- PHPMyAdmin: http://localhost:8081"
	@echo "- Maildev: http://localhost:8082"
	@echo ""

# Stop services
down:
	docker-compose down

# Restart services
restart:
	docker-compose restart

# View logs
logs:
	docker-compose logs -f dolibarr

# View database logs
logs-db:
	docker-compose logs -f mariadb

# Shell access to Dolibarr container
shell:
	docker-compose exec dolibarr bash

# MySQL shell access
db-shell:
	@docker-compose exec mariadb mysql -u dolibarr -pdolibarr_pwd dolibarr

# Show container status
status:
	@docker-compose ps

# Backup database and files
backup:
	@mkdir -p backups
	@echo "Creating backup..."
	@docker-compose exec mariadb mysqldump -u root -pdolibarr_root_pwd dolibarr | gzip > backups/db_$(shell date +%Y%m%d_%H%M%S).sql.gz
	@tar -czf backups/documents_$(shell date +%Y%m%d_%H%M%S).tar.gz documents/ 2>/dev/null || true
	@tar -czf backups/conf_$(shell date +%Y%m%d_%H%M%S).tar.gz conf/ 2>/dev/null || true
	@echo "Backup completed in ./backups/"

# Restore from backup (requires BACKUP_DATE parameter)
restore:
	@if [ -z "$(BACKUP_DATE)" ]; then \
		echo "Usage: make restore BACKUP_DATE=YYYYMMDD_HHMMSS"; \
		echo "Available backups:"; \
		ls -la backups/db_*.sql.gz 2>/dev/null | awk '{print "  " $$9}' | sed 's/.*db_//' | sed 's/.sql.gz//'; \
	else \
		echo "Restoring from backup $(BACKUP_DATE)..."; \
		gunzip < backups/db_$(BACKUP_DATE).sql.gz | docker-compose exec -T mariadb mysql -u root -pdolibarr_root_pwd dolibarr; \
		tar -xzf backups/documents_$(BACKUP_DATE).tar.gz 2>/dev/null || true; \
		tar -xzf backups/conf_$(BACKUP_DATE).tar.gz 2>/dev/null || true; \
		echo "Restore completed"; \
	fi

# Clean everything (CAUTION: Removes all data!)
clean:
	@echo "WARNING: This will remove all containers and volumes!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker-compose down -v
	rm -rf conf/* documents/* custom/*

# Complete reset
reset: clean
	@echo "Rebuilding from scratch..."
	docker-compose build --no-cache
	docker-compose up -d
	@echo ""
	@echo "Reset complete. Fresh installation available at http://localhost:8080"

# Quick development setup
dev:
	@echo "Setting up development environment..."
	@sed -i 's/DOLI_DEV_MODE=0/DOLI_DEV_MODE=1/' .env 2>/dev/null || sed -i '' 's/DOLI_DEV_MODE=0/DOLI_DEV_MODE=1/' .env
	@$(MAKE) restart
	@echo "Development mode enabled"

# Production setup check
prod-check:
	@echo "Production readiness check:"
	@echo -n "✓ Strong database password: "
	@grep -q 'MYSQL_ROOT_PASSWORD=.*[A-Z].*[a-z].*[0-9]' .env && echo "YES" || echo "NO - Update MYSQL_ROOT_PASSWORD"
	@echo -n "✓ Strong admin password: "
	@grep -q 'DOLI_ADMIN_PASSWORD=.*[A-Z].*[a-z].*[0-9]' .env && echo "YES" || echo "NO - Update DOLI_ADMIN_PASSWORD"
	@echo -n "✓ Development mode disabled: "
	@grep -q 'DOLI_DEV_MODE=0' .env && echo "YES" || echo "NO - Set DOLI_DEV_MODE=0"
	@echo -n "✓ HTTPS configured: "
	@grep -q 'DOLI_URL_ROOT=https://' .env && echo "YES" || echo "NO - Configure HTTPS reverse proxy"

# Display environment info
info:
	@echo "Dolibarr Docker Environment Info:"
	@echo "================================="
	@docker --version
	@docker-compose --version
	@echo ""
	@echo "Current configuration (.env):"
	@echo "-----------------------------"
	@grep -E "^(WEB_PORT|MYSQL_DATABASE|DOLI_ADMIN_LOGIN|DOLI_DEV_MODE|TZ)=" .env
	@echo ""
	@echo "Container status:"
	@echo "-----------------"
	@docker-compose ps
