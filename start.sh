#!/bin/bash

# Dolibarr Docker Quick Start Script
# This script sets up and starts Dolibarr with Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     Dolibarr Docker Quick Start          ║"
echo "║           with WFS Logo                  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check Docker installation
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    # Try docker compose (v2)
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed. Please install Docker Compose.${NC}"
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    # Use docker compose v2
    DOCKER_COMPOSE="docker compose"
else
    # Use docker-compose v1
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo -e "${GREEN}✓ Docker Compose is installed${NC}"

# Check if .env exists, if not create from example
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo -e "${YELLOW}Creating .env file from template...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✓ Environment file created${NC}"
    else
        echo -e "${RED}No .env.example file found!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Environment file exists${NC}"
fi

# Create necessary directories
echo -e "${YELLOW}Creating required directories...${NC}"
mkdir -p conf custom documents backups
echo -e "${GREEN}✓ Directories created${NC}"

# Make entrypoint executable
if [ -f docker-entrypoint.sh ]; then
    chmod +x docker-entrypoint.sh
    echo -e "${GREEN}✓ Entrypoint script is executable${NC}"
fi

# Stop any existing containers
echo -e "${YELLOW}Checking for existing containers...${NC}"
if $DOCKER_COMPOSE ps -q 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}Stopping existing containers...${NC}"
    $DOCKER_COMPOSE down
fi

# Build and start containers
echo -e "${YELLOW}Building Docker images...${NC}"
$DOCKER_COMPOSE build

echo -e "${YELLOW}Starting services...${NC}"
$DOCKER_COMPOSE up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 5

# Check if services are running
if $DOCKER_COMPOSE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Services are running${NC}"
else
    echo -e "${RED}Services failed to start. Check logs with: $DOCKER_COMPOSE logs${NC}"
    exit 1
fi

# Display access information
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         🎉 Dolibarr is ready! 🎉                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo -e "  ${GREEN}➜${NC} Dolibarr:   ${BLUE}http://localhost:8080${NC}"
echo -e "  ${GREEN}➜${NC} PHPMyAdmin: ${BLUE}http://localhost:8081${NC} (optional - run: make up-tools)"
echo ""
echo -e "${BLUE}Default Credentials:${NC}"
echo -e "  ${GREEN}➜${NC} Username: ${YELLOW}admin${NC}"
echo -e "  ${GREEN}➜${NC} Password: ${YELLOW}admin123${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  ${GREEN}➜${NC} View logs:        ${YELLOW}$DOCKER_COMPOSE logs -f dolibarr${NC}"
echo -e "  ${GREEN}➜${NC} Stop services:    ${YELLOW}$DOCKER_COMPOSE down${NC}"
echo -e "  ${GREEN}➜${NC} Open shell:       ${YELLOW}$DOCKER_COMPOSE exec dolibarr bash${NC}"
echo -e "  ${GREEN}➜${NC} Database shell:   ${YELLOW}$DOCKER_COMPOSE exec mariadb mysql -u dolibarr -p${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "  ${GREEN}➜${NC} See ${YELLOW}DOCKER_README.md${NC} for detailed documentation"
echo -e "  ${GREEN}➜${NC} Use ${YELLOW}make help${NC} for available commands"
echo ""

# Option to open browser
if command -v xdg-open &> /dev/null; then
    read -p "Would you like to open Dolibarr in your browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "http://localhost:8080"
    fi
elif command -v open &> /dev/null; then
    read -p "Would you like to open Dolibarr in your browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "http://localhost:8080"
    fi
fi

echo -e "${GREEN}Setup complete! Enjoy using Dolibarr with your custom WFS logo.${NC}"
