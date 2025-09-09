# WSO2 Micro Integrator Project Makefile
# Platform-independent build and deployment automation

# Platform detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    MAVEN := mvn
    WSO2_START := micro-integrator.sh
    JAVA_HOME_CHECK := $(shell echo $$JAVA_HOME)
    PATH_SEP := :
    EXEC_EXT := 
endif
ifeq ($(UNAME_S),Darwin)
    MAVEN := mvn
    WSO2_START := micro-integrator.sh
    JAVA_HOME_CHECK := $(shell echo $$JAVA_HOME)
    PATH_SEP := :
    EXEC_EXT := 
endif
ifeq ($(OS),Windows_NT)
    MAVEN := mvn.cmd
    WSO2_START := micro-integrator.bat
    JAVA_HOME_CHECK := $(shell echo %JAVA_HOME%)
    PATH_SEP := ;
    EXEC_EXT := .exe
endif

# Project variables
PROJECT_NAME := proxyserver
VERSION := 1.0.0
CAPP_NAME := $(PROJECT_NAME)_$(VERSION).car
TARGET_DIR := target
DEPLOYMENT_DIR := deployment
WSO2_MI_HOME := $(shell echo $$WSO2_MI_HOME)
WSO2_CARBONAPPS_DIR := $(WSO2_MI_HOME)/repository/deployment/server/carbonapps
WSO2_LOGS_DIR := $(WSO2_MI_HOME)/repository/logs

# Colors for output (works on Unix-like systems)
ifneq ($(OS),Windows_NT)
    GREEN := \033[0;32m
    YELLOW := \033[1;33m
    RED := \033[0;31m
    NC := \033[0m # No Color
else
    GREEN := 
    YELLOW := 
    RED := 
    NC := 
endif

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help:
	@echo "$(GREEN)WSO2 Micro Integrator Project - Available Commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup & Environment:$(NC)"
	@echo "  check-env      - Check environment prerequisites"
	@echo "  setup          - Initial project setup"
	@echo ""
	@echo "$(YELLOW)Build & Package:$(NC)"
	@echo "  clean          - Clean target directory"
	@echo "  compile        - Compile the project"
	@echo "  package        - Build Carbon Application (.car file)"
	@echo "  build          - Clean, compile and package"
	@echo ""
	@echo "$(YELLOW)Deployment:$(NC)"
	@echo "  deploy         - Deploy Carbon App to WSO2 MI"
	@echo "  undeploy       - Remove Carbon App from WSO2 MI"
	@echo "  hot-deploy     - Build and hot-deploy to running WSO2 MI"
	@echo ""
	@echo "$(YELLOW)WSO2 MI Operations:$(NC)"
	@echo "  start-wso2     - Start WSO2 Micro Integrator"
	@echo "  start-wso2-bg  - Start WSO2 MI in background"
	@echo "  stop-wso2      - Stop WSO2 Micro Integrator"
	@echo "  restart-wso2   - Restart WSO2 MI"
	@echo "  status         - Check WSO2 MI status"
	@echo "  logs           - Show WSO2 MI logs"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  dev            - Start development environment"
	@echo "  test-apis      - Test deployed APIs"
	@echo "  monitor        - Monitor WSO2 MI logs in real-time"
	@echo ""
	@echo "$(YELLOW)All-in-one:$(NC)"
	@echo "  run            - Build, deploy and start WSO2 MI"
	@echo "  stop-all       - Stop all services"

# Environment checks
.PHONY: check-env
check-env:
	@echo "$(YELLOW)Checking environment setup...$(NC)"
	@echo "OS: $(UNAME_S)"
	@echo "Java Home: $(JAVA_HOME_CHECK)"
	@if [ -z "$(JAVA_HOME_CHECK)" ]; then \
		echo "$(RED)Error: JAVA_HOME not set$(NC)"; \
		exit 1; \
	fi
	@echo "Maven: $(shell $(MAVEN) -version 2>/dev/null | head -1 || echo 'Not found')"
	@if ! command -v $(MAVEN) >/dev/null 2>&1; then \
		echo "$(RED)Error: Maven not found$(NC)"; \
		exit 1; \
	fi
	@echo "WSO2 MI Home: $(WSO2_MI_HOME)"
	@if [ -z "$(WSO2_MI_HOME)" ]; then \
		echo "$(RED)Error: WSO2_MI_HOME not set$(NC)"; \
		echo "Please set WSO2_MI_HOME environment variable"; \
		exit 1; \
	fi
	@if [ ! -d "$(WSO2_MI_HOME)" ]; then \
		echo "$(RED)Error: WSO2 MI directory not found: $(WSO2_MI_HOME)$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Environment check passed!$(NC)"

# Setup project
.PHONY: setup
setup: check-env
	@echo "$(YELLOW)Setting up project...$(NC)"
	@mkdir -p $(TARGET_DIR)
	@mkdir -p $(DEPLOYMENT_DIR)
	@echo "$(GREEN)Project setup complete!$(NC)"

# Clean target directory
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning project...$(NC)"
	$(MAVEN) clean
	@echo "$(GREEN)Clean complete!$(NC)"

# Compile project
.PHONY: compile
compile: check-env
	@echo "$(YELLOW)Compiling project...$(NC)"
	$(MAVEN) compile
	@echo "$(GREEN)Compilation complete!$(NC)"

# Package Carbon Application
.PHONY: package
package: check-env
	@echo "$(YELLOW)Building Carbon Application...$(NC)"
	$(MAVEN) package
	@if [ -f "$(TARGET_DIR)/$(CAPP_NAME)" ]; then \
		echo "$(GREEN)Carbon App built successfully: $(CAPP_NAME)$(NC)"; \
	else \
		echo "$(RED)Error: Carbon App not found$(NC)"; \
		exit 1; \
	fi

# Build everything
.PHONY: build
build: clean package

# Deploy Carbon App to WSO2 MI
.PHONY: deploy
deploy: package
	@echo "$(YELLOW)Deploying Carbon Application...$(NC)"
	@if [ ! -d "$(WSO2_CARBONAPPS_DIR)" ]; then \
		echo "$(RED)Error: WSO2 carbonapps directory not found$(NC)"; \
		exit 1; \
	fi
	cp $(TARGET_DIR)/$(CAPP_NAME) $(WSO2_CARBONAPPS_DIR)/
	@echo "$(GREEN)Deployment complete!$(NC)"

# Remove Carbon App from WSO2 MI
.PHONY: undeploy
undeploy:
	@echo "$(YELLOW)Removing Carbon Application...$(NC)"
	@if [ -f "$(WSO2_CARBONAPPS_DIR)/$(CAPP_NAME)" ]; then \
		rm -f $(WSO2_CARBONAPPS_DIR)/$(CAPP_NAME); \
		echo "$(GREEN)Carbon App removed$(NC)"; \
	else \
		echo "$(YELLOW)Carbon App not found in deployment directory$(NC)"; \
	fi

# Hot deploy (build and deploy to running WSO2 MI)
.PHONY: hot-deploy
hot-deploy: package
	@echo "$(YELLOW)Hot deploying to running WSO2 MI...$(NC)"
	cp $(TARGET_DIR)/$(CAPP_NAME) $(WSO2_CARBONAPPS_DIR)/
	@echo "$(GREEN)Hot deployment complete!$(NC)"

# Start WSO2 Micro Integrator
.PHONY: start-wso2
start-wso2: check-env
	@echo "$(YELLOW)Starting WSO2 Micro Integrator...$(NC)"
	cd $(WSO2_MI_HOME)/bin && ./$(WSO2_START)

# Start WSO2 MI in background
.PHONY: start-wso2-bg
start-wso2-bg: check-env
	@echo "$(YELLOW)Starting WSO2 Micro Integrator in background...$(NC)"
ifneq ($(OS),Windows_NT)
	cd $(WSO2_MI_HOME)/bin && nohup ./$(WSO2_START) > $(WSO2_LOGS_DIR)/wso2carbon.log 2>&1 &
else
	cd $(WSO2_MI_HOME)/bin && start $(WSO2_START)
endif
	@sleep 5
	@echo "$(GREEN)WSO2 MI started in background$(NC)"

# Stop WSO2 Micro Integrator
.PHONY: stop-wso2
stop-wso2:
	@echo "$(YELLOW)Stopping WSO2 Micro Integrator...$(NC)"
ifneq ($(OS),Windows_NT)
	@pkill -f "micro-integrator" || echo "WSO2 MI not running"
else
	@taskkill /F /IM java.exe /FI "COMMANDLINE eq *micro-integrator*" 2>nul || echo "WSO2 MI not running"
endif
	@echo "$(GREEN)WSO2 MI stopped$(NC)"

# Restart WSO2 MI
.PHONY: restart-wso2
restart-wso2: stop-wso2
	@sleep 3
	$(MAKE) start-wso2-bg

# Check WSO2 MI status
.PHONY: status
status:
	@echo "$(YELLOW)Checking WSO2 MI status...$(NC)"
	@curl -s -f http://localhost:8290/health >/dev/null 2>&1 && \
		echo "$(GREEN)WSO2 MI is running$(NC)" || \
		echo "$(RED)WSO2 MI is not running$(NC)"

# Show WSO2 MI logs
.PHONY: logs
logs:
	@echo "$(YELLOW)WSO2 MI Logs:$(NC)"
	@if [ -f "$(WSO2_LOGS_DIR)/wso2carbon.log" ]; then \
		tail -n 50 $(WSO2_LOGS_DIR)/wso2carbon.log; \
	else \
		echo "$(RED)Log file not found$(NC)"; \
	fi

# Monitor logs in real-time
.PHONY: monitor
monitor:
	@echo "$(YELLOW)Monitoring WSO2 MI logs (Ctrl+C to stop)...$(NC)"
	@if [ -f "$(WSO2_LOGS_DIR)/wso2carbon.log" ]; then \
		tail -f $(WSO2_LOGS_DIR)/wso2carbon.log; \
	else \
		echo "$(RED)Log file not found$(NC)"; \
	fi

# Development environment
.PHONY: dev
dev: build deploy start-wso2-bg
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "APIs available at:"
	@echo "  - newOrder API: http://localhost:8290/newOrder"
	@echo "  - Proxy Service: http://localhost:8290/services/ImmediateResponseProxy"

# Test APIs
.PHONY: test-apis
test-apis:
	@echo "$(YELLOW)Testing deployed APIs...$(NC)"
	@echo "Testing newOrder API..."
	@curl -s -f http://localhost:8290/newOrder/health >/dev/null 2>&1 && \
		echo "$(GREEN)newOrder API is accessible$(NC)" || \
		echo "$(RED)newOrder API is not accessible$(NC)"
	@echo "Testing proxy service..."
	@curl -s -f http://localhost:8290/services/ImmediateResponseProxy?wsdl >/dev/null 2>&1 && \
		echo "$(GREEN)Proxy service is accessible$(NC)" || \
		echo "$(RED)Proxy service is not accessible$(NC)"

# Run everything (build, deploy, start)
.PHONY: run
run: build deploy start-wso2-bg
	@sleep 10
	$(MAKE) test-apis
	@echo "$(GREEN)Project is running!$(NC)"

# Stop all services
.PHONY: stop-all
stop-all: stop-wso2
	@echo "$(GREEN)All services stopped$(NC)"

# Docker support (optional)
.PHONY: docker-build
docker-build:
	@if [ -f "Dockerfile" ]; then \
		echo "$(YELLOW)Building Docker image...$(NC)"; \
		docker build -t $(PROJECT_NAME):$(VERSION) .; \
		echo "$(GREEN)Docker image built$(NC)"; \
	else \
		echo "$(RED)Dockerfile not found$(NC)"; \
	fi

.PHONY: docker-run
docker-run:
	@echo "$(YELLOW)Running Docker container...$(NC)"
	docker run -d -p 8290:8290 -p 8253:8253 --name $(PROJECT_NAME) $(PROJECT_NAME):$(VERSION)
	@echo "$(GREEN)Docker container started$(NC)"

.PHONY: docker-stop
docker-stop:
	@echo "$(YELLOW)Stopping Docker container...$(NC)"
	docker stop $(PROJECT_NAME) && docker rm $(PROJECT_NAME)
	@echo "$(GREEN)Docker container stopped$(NC)"

# Install connectors
.PHONY: install-connectors
install-connectors:
	@echo "$(YELLOW)Installing connectors...$(NC)"
	@if [ -d "$(TARGET_DIR)/dependency" ]; then \
		cp -r $(TARGET_DIR)/dependency/* $(WSO2_MI_HOME)/lib/; \
		echo "$(GREEN)Connectors installed$(NC)"; \
	else \
		echo "$(YELLOW)No connectors found to install$(NC)"; \
	fi
