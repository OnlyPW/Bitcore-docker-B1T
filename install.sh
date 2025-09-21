#!/bin/bash

# Bit Core Docker Installation Script
# For Linux/macOS systems

set -e

echo "========================================"
echo "   Bit Core Docker Installation"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
print_status "Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    echo "Please ensure Docker is running and up to date"
    exit 1
fi

print_success "Docker and Docker Compose are available"
echo

# Create directories if they don't exist
print_status "Creating directories..."
mkdir -p config data
print_success "Directories created/verified"
echo

# Build the Docker image
print_status "Building Bit Core Docker image..."
if ! docker compose build; then
    print_error "Failed to build Docker image"
    exit 1
fi

print_success "Docker image built successfully!"
echo

# Start the container
print_status "Starting Bit Core container..."
if ! docker compose up -d; then
    print_error "Failed to start container"
    exit 1
fi

echo
echo "========================================"
echo "   Installation completed successfully!"
echo "========================================"
echo
print_success "Bit Core is now running in Docker"
echo
echo "Useful commands:"
echo "  docker compose ps          - Check container status"
echo "  docker compose logs -f     - View logs"
echo "  docker compose down        - Stop container"
echo "  docker compose up -d       - Start container"
echo
echo "Configuration files:"
echo "  config/bit.conf            - Configuration template"
echo "  data/bit.conf              - Active configuration"
echo "  data/                      - Blockchain data directory"
echo
echo "RPC Access:"
echo "  Host: localhost"
echo "  Port: 8332"
echo "  User: user (default)"
echo "  Password: changeme (default)"
echo

# Show container status
print_status "Container Status:"
docker compose ps

echo
print_success "Installation complete! Bit Core is running."
