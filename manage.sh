#!/bin/bash

# Bit Core Docker Management Script
# For Linux/macOS systems

set -e

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

show_menu() {
    echo "========================================"
    echo "   Bit Core Docker Management"
    echo "========================================"
    echo
    echo "Please select an option:"
    echo
    echo "1. Start Bit Core"
    echo "2. Stop Bit Core"
    echo "3. Restart Bit Core"
    echo "4. View Logs"
    echo "5. Check Status"
    echo "6. Update Configuration"
    echo "7. Clean Data (WARNING: Deletes blockchain data)"
    echo "8. Exit"
    echo
}

start_bitcore() {
    print_status "Starting Bit Core..."
    if docker compose up -d; then
        print_success "Bit Core started successfully!"
    else
        print_error "Failed to start Bit Core"
    fi
}

stop_bitcore() {
    print_status "Stopping Bit Core..."
    if docker compose down; then
        print_success "Bit Core stopped successfully!"
    else
        print_error "Failed to stop Bit Core"
    fi
}

restart_bitcore() {
    print_status "Restarting Bit Core..."
    docker compose down
    if docker compose up -d; then
        print_success "Bit Core restarted successfully!"
    else
        print_error "Failed to restart Bit Core"
    fi
}

view_logs() {
    print_status "Viewing Bit Core logs (Press Ctrl+C to exit)..."
    echo
    docker compose logs -f
}

check_status() {
    print_status "Bit Core Status:"
    echo
    docker compose ps
    echo
    print_status "Recent logs:"
    docker compose logs --tail=10
}

update_config() {
    print_status "Updating configuration..."
    echo
    echo "This will restart Bit Core with the updated config/bit.conf template."
    echo
    read -p "Continue? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Stopping Bit Core..."
        docker compose down
        print_status "Removing old configuration..."
        rm -f data/bit.conf
        print_status "Starting Bit Core with new configuration..."
        if docker compose up -d; then
            print_success "Configuration updated successfully!"
        else
            print_error "Failed to start Bit Core with new configuration"
        fi
    else
        print_warning "Update cancelled."
    fi
}

clean_data() {
    print_warning "WARNING: This will delete ALL blockchain data!"
    echo "This includes:"
    echo "- Wallet data"
    echo "- Blockchain blocks"
    echo "- Transaction index"
    echo "- All other Bit Core data"
    echo
    read -p "Are you sure you want to continue? Type 'DELETE' to confirm: " confirm
    if [[ $confirm == "DELETE" ]]; then
        print_status "Stopping Bit Core..."
        docker compose down
        print_status "Removing all data..."
        rm -rf data/*
        print_status "Starting Bit Core with fresh data..."
        if docker compose up -d; then
            print_success "Data cleaned successfully!"
        else
            print_error "Failed to start Bit Core with fresh data"
        fi
    else
        print_warning "Clean cancelled."
    fi
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1)
            start_bitcore
            ;;
        2)
            stop_bitcore
            ;;
        3)
            restart_bitcore
            ;;
        4)
            view_logs
            ;;
        5)
            check_status
            ;;
        6)
            update_config
            ;;
        7)
            clean_data
            ;;
        8)
            echo
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
    echo
done
