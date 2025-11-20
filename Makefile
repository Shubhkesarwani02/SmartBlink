# SmartBlink Makefile
# Convenience commands for development

.PHONY: help setup start stop clean seed test logs db-shell

help: ## Show this help message
	@echo "SmartBlink - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## 🚀 Complete setup (database + schema + seed)
	@./quick-start.sh

start: ## ▶️  Start all services
	@echo "🚀 Starting all services..."
	@docker-compose up -d
	@echo "✅ Services started!"
	@echo "   Frontend: http://localhost:3000"
	@echo "   Backend:  http://localhost:8000"
	@echo "   API Docs: http://localhost:8000/docs"

stop: ## ⏸️  Stop all services
	@echo "⏹️  Stopping services..."
	@docker-compose down
	@echo "✅ Services stopped"

restart: ## 🔄 Restart all services
	@make stop
	@make start

clean: ## 🧹 Stop and remove all containers, volumes, images
	@echo "⚠️  This will delete all data. Are you sure? [y/N]"
	@read response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		docker-compose down -v --rmi local; \
		echo "✅ Cleaned up"; \
	else \
		echo "❌ Cancelled"; \
	fi

seed: ## 🌱 Seed database with sample data
	@echo "🌱 Seeding database..."
	@docker-compose exec backend python seed.py

test: ## 🧪 Run database tests
	@echo "🧪 Running tests..."
	@docker-compose exec backend python test_db.py

validate: ## ✅ Run comprehensive Phase 1 validation
	@./backend/validate.sh

logs: ## 📋 Show logs for all services
	@docker-compose logs -f

logs-backend: ## 📋 Show backend logs
	@docker-compose logs -f backend

logs-frontend: ## 📋 Show frontend logs
	@docker-compose logs -f frontend

db-shell: ## 🐚 Open PostgreSQL shell
	@docker-compose exec postgres psql -U smartblink -d smartblink

db-migrate: ## 📝 Generate and apply database migration
	@echo "📝 Running migrations..."
	@docker-compose exec backend bash -c "cd /app && prisma generate && prisma db push"

db-reset: ## ⚠️  Reset database (deletes all data!)
	@echo "⚠️  This will delete ALL data. Are you sure? [y/N]"
	@read response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		docker-compose exec backend bash -c "cd /app && prisma migrate reset --force"; \
		echo "✅ Database reset"; \
	else \
		echo "❌ Cancelled"; \
	fi

status: ## 📊 Show service status
	@docker-compose ps

build: ## 🔨 Rebuild all containers
	@echo "🔨 Building containers..."
	@docker-compose build
	@echo "✅ Build complete"

dev-backend: ## 💻 Start backend in dev mode (local, no Docker)
	@cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend: ## 💻 Start frontend in dev mode (local, no Docker)
	@cd frontend && npm run dev

install-backend: ## 📦 Install backend dependencies (local)
	@cd backend && pip install -r requirements.txt

install-frontend: ## 📦 Install frontend dependencies (local)
	@cd frontend && npm install

format-backend: ## ✨ Format backend code
	@cd backend && black . && isort .

lint-backend: ## 🔍 Lint backend code
	@cd backend && pylint app/

phase1: ## ✅ View Phase 1 completion status
	@cat docs/PHASE1_COMPLETE.md

docs: ## 📚 Open documentation
	@echo "📚 Available documentation:"
	@echo "   README.md - Main documentation"
	@echo "   docs/PHASE1_DATABASE_SETUP.md - Database setup guide"
	@echo "   docs/PHASE1_COMPLETE.md - Phase 1 summary"
	@echo "   docs/ARCHITECTURE.md - System architecture"

# Default target
.DEFAULT_GOAL := help
