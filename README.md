# Restaurants API

A Rails API for restaurant menu management with support for multiple restaurants, menus, and menu items.

## Overview

This API provides endpoints to manage restaurant data, including menus and menu items. It supports JSON import functionality for bulk data operations and maintains data integrity through database-level constraints.

## Technology Stack

- **Framework**: Ruby on Rails 8.0
- **Database**: PostgreSQL
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Ruby Version**: 3.2.2
- **Background Jobs**: Solid Queue with Mission Control Jobs UI

## Project Structure

```
app/
├── controllers/
│   ├── restaurants_controller.rb
│   ├── menus_controller.rb
│   ├── menu_items_controller.rb
│   └── import_controller.rb
├── models/
│   ├── restaurant.rb
│   ├── menu.rb
│   ├── menu_item.rb
│   └── menu_menu_item.rb
└── services/
    └── restaurant_import_service.rb
```

## Database Schema

### Tables

- **restaurants**: Stores restaurant information
- **menus**: Stores menu information, belongs to a restaurant
- **menu_items**: Stores menu item information (globally unique names)
- **menu_menu_items**: Join table between menus and menu items with pricing

### Key Constraints

- Menu item names are globally unique at the database level
- Menu names are unique per restaurant
- Menu-item combinations are unique within a menu
- All foreign key relationships are properly enforced

## API Endpoints

### Restaurants

- `GET /restaurants` - List all restaurants
- `GET /restaurants/:id` - Get restaurant details with menus and items
- `GET /restaurants/:id/menus` - Get all menus for a restaurant
- `GET /restaurants/:id/menu_items` - Get all menu items for a restaurant

### Menus

- `GET /menus` - List all menus
- `GET /menus/:id` - Get menu details with items and prices

### Menu Items

- `GET /menu_items` - List all menu items
- `GET /menu_items/:id` - Get menu item details

### Import

- `POST /import` - Import JSON data from request body (asynchronous)
- `POST /import/upload` - Import JSON data from file upload (asynchronous)
- `GET /import/status/:job_id` - Basic job status (processing indicator)

## Implementation Levels

### Level 1: Basic Menu Management

**Features Implemented:**
- Menu and MenuItem models with one-to-many relationship
- Basic CRUD endpoints for menus and menu items
- Price handling through the join table
- Comprehensive unit tests for models and controllers

**Key Design Decisions:**
- Used join table (menu_menu_items) to handle pricing variations
- Price belongs to the relationship, not the menu item itself
- Basic validation and error handling

### Level 2: Multiple Restaurants and Menus

**Features Implemented:**
- Restaurant model with multiple menus
- Nested routing structure for better API organization
- Database-level uniqueness constraints
- Support for menu items appearing in multiple menus with different prices

**Key Design Decisions:**
- Nested resources for intuitive API structure
- Database-level uniqueness for data integrity
- Maintained backward compatibility with global endpoints

### Level 3: JSON Import System

**Features Implemented:**
- HTTP endpoints for JSON import (body and file upload)
- Service object for business logic separation
- Transaction safety with automatic rollback on errors
- Duplicate consolidation within menus
- Comprehensive logging and error handling
- Support for both 'menu_items' and 'dishes' keys in JSON

**Key Design Decisions:**
- Service object pattern for complex import logic
- Transaction safety prevents partial imports
- Flexible JSON key mapping for future extensibility
- Idempotent operations (re-importing updates existing records)

## JSON Import Format

The API accepts JSON data in the following format:

```json
{
  "restaurants": [
    {
      "name": "Restaurant Name",
      "menus": [
        {
          "name": "Menu Name",
          "menu_items": [
            {
              "name": "Item Name",
              "price": 9.99
            }
          ]
        }
      ]
    }
  ]
}
```

**Alternative Keys:**
- `dishes` can be used instead of `menu_items`

**Import Features:**
- Automatic duplicate consolidation within menus
- Transaction safety with rollback on errors
- Detailed logging for each operation
- Error reporting with specific failure reasons
- **File size limit**: Maximum 5MB per import (project design decision)
- **Asynchronous processing**: Background job processing for better performance
- **Real-time status**: Check import progress via job ID

## Testing

The project includes comprehensive testing:

- **Unit Tests**: Model validations, associations, and business logic
- **Controller Tests**: API endpoint behavior and error handling
- **Integration Tests**: End-to-end workflow testing
- **Service Tests**: Import service functionality and edge cases

**Test Coverage:**
- All models have validation and association tests
- All controllers have request and response tests
- Import service has comprehensive error handling tests
- Integration tests cover complete user workflows

## Background Job Management

The application uses **Solid Queue** for background job processing and **Mission Control Jobs** for a web-based job management interface.

### Mission Control Jobs UI

Access the job management interface at `/jobs` to monitor and manage background jobs:

- **Queues Tab**: View all job queues and their status
- **In-Progress Jobs**: Monitor currently running jobs
- **Failed Jobs**: Inspect, retry, or discard failed jobs
- **Workers Tab**: Monitor job workers and their status
- **Job Details**: Inspect individual job information and arguments

### Accessing Mission Control Jobs

The interface is protected with HTTP Basic Authentication:
- **Username**: `test`
- **Password**: `password`

### Job Management Features

- **Real-time Monitoring**: Live updates of job status and progress
- **Bulk Operations**: Retry or discard multiple failed jobs at once
- **Job Filtering**: Filter jobs by queue name, job class, and status
- **Queue Pausing**: Pause/unpause queues to control job processing


## Performance Testing

The project includes performance testing scripts to evaluate the import service with different JSON sizes:

- **`quick_performance_test.rb`**: Quick test for different file sizes (100KB to 4MB)
- **`benchmark_upload_performance.rb`**: Comprehensive benchmark with detailed analysis

These scripts help identify performance characteristics and potential optimizations for the import service.

## Getting Started

### Prerequisites

- **Docker Setup**: Docker + Docker Compose (for Option 1)
- **Manual Setup**: Ruby 3.2.2, PostgreSQL 16+, Bundler (for Option 2)

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/reuel-freitas/restaurants-api.git
   cd restaurants-api
   ```

2. **Choose your setup method** (see details below)

### Option 1: Docker (Recommended for Development)

The easiest way to get started is using Docker. This approach ensures consistent environments across different machines and eliminates setup issues.

#### Quick Start

1. **Start the application**
   ```bash
   docker compose up
   ```

2. **Access the application**
   - API: http://localhost:3000
   - PostgreSQL: localhost:5433 (username: postgres, password: postgres)
   - Mission Control Jobs: http://localhost:3000/jobs (test/password)

3. **Stop the application**
   ```bash
   docker compose down
   ```

#### Docker Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Rebuild after changes
docker compose build

# Stop and remove containers
docker compose down

# Reset everything (containers, volumes, images)
docker compose down -v --rmi all
```

#### Development with Docker

- **Hot Reload**: Code changes are automatically reflected
- **Database**: PostgreSQL data persists between restarts
- **Gems**: Automatically installed on container startup
- **No local Ruby/PostgreSQL setup required**

---

### Option 2: Manual Setup

For developers who prefer to run the application directly on their machine.

#### Prerequisites

- Ruby 3.2.2
- PostgreSQL 16+
- Bundler
- Node.js (for asset compilation if needed)

#### Installation Steps

1. **Install Ruby 3.2.2**
   ```bash
   # Using rbenv
   rbenv install 3.2.2
   rbenv local 3.2.2
   
   # Using rvm
   rvm install 3.2.2
   rvm use 3.2.2
   
   # Using asdf
   asdf install ruby 3.2.2
   asdf local ruby 3.2.2
   ```

2. **Install PostgreSQL**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib libpq-dev
   
   # macOS with Homebrew
   brew install postgresql
   
   # Start PostgreSQL service
   sudo systemctl start postgresql  # Linux
   brew services start postgresql   # macOS
   ```

3. **Setup the project**
   ```bash
   # Install Ruby dependencies
   bundle install
   
   # Create database user (if needed)
   sudo -u postgres createuser -s $USER
   
   # Setup database
   rails db:create
   rails db:migrate
   ```

4. **Start the application**
   ```bash
   # Start Rails server
   bin/rails server
   
   # In another terminal, start background jobs (optional)
   bin/jobs
   ```

5. **Access the application**
   - API: http://localhost:3000
   - PostgreSQL: localhost:5432
   - Mission Control Jobs: http://localhost:3000/jobs (test/password)

#### Manual Setup Commands

```bash
# Database operations
rails db:create          # Create database
rails db:migrate         # Run migrations
rails db:seed            # Seed data (if available)
rails db:reset           # Reset database

# Rails console
rails console            # Interactive Ruby console
rails routes             # View all routes
rails middleware         # View middleware stack

# Background jobs
bin/jobs
```

#### Environment Variables

Create a `.env` file in the project root:

```bash
# Database
DATABASE_URL=postgresql://localhost/restaurants_api_development
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=restaurants_api_development
POSTGRES_USER=your_username
POSTGRES_PASSWORD=your_password

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key_here
```

---

### Running Tests

Both setup options support the same testing commands:

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
bundle exec rspec spec/services/

# Run tests with coverage
COVERAGE=true bundle exec rspec

# Run tests in parallel (if configured)
bundle exec parallel_rspec spec/
```

---

### Troubleshooting

#### Docker Issues

**Container won't start or permission errors:**
```bash
# Reset Docker environment
docker compose down -v --rmi all
docker system prune -f
docker compose up --build
```

**Port already in use:**
```bash
# Check what's using the port
sudo lsof -i :3000
sudo lsof -i :5433

# Kill the process or change ports in docker-compose.yml
```

**Database connection issues:**
```bash
# Check container status
docker compose ps

# View database logs
docker compose logs postgres

# Reset database
docker compose down -v
docker compose up
```

#### Manual Setup Issues

**Ruby version mismatch:**
```bash
# Check current Ruby version
ruby --version

# Install correct version with your version manager
rbenv install 3.2.2
rvm install 3.2.2
asdf install ruby 3.2.2
```

**PostgreSQL connection issues:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start PostgreSQL service
sudo systemctl start postgresql

# Check if user exists
sudo -u postgres psql -c "\du"

# Create user if needed
sudo -u postgres createuser -s $USER
```

**Bundle install fails:**
```bash
# Clear bundle cache
bundle clean --force

# Install with specific platform
bundle install --platform x86_64-linux

# Check for system dependencies
sudo apt-get install build-essential libpq-dev
```
```

## API Usage Examples

### Import JSON Data (Asynchronous)

```bash
# Import from request body (returns job ID immediately)
curl -X POST http://localhost:3000/import \
  -H "Content-Type: application/json" \
  -d @restaurant_data.json

# Response:
# {
#   "success": true,
#   "message": "Import job enqueued successfully",
#   "job_id": "abc123",
#   "status": "processing",
#   "check_status_command": "curl http://localhost:3000/import/status/abc123"
# }

# Import from file upload (returns job ID immediately)
curl -X POST http://localhost:3000/import/upload \
  -F "file=@restaurant_data.json"

# Response:
# {
#   "success": true,
#   "message": "Import job enqueued successfully",
#   "job_id": "abc123",
#   "status": "processing",
#   "check_status_command": "curl http://localhost:3000/import/status/abc123"
# }

# Check import status (copy and paste the command from the response)
curl http://localhost:3000/import/status/abc123

# Response:
# {
#   "success": true,
#   "job_id": "abc123",
#   "status": {
#     "state": "processing",
#     "message": "Job is being processed asynchronously. Check application logs for completion details."
#   }
# }

# Monitor jobs via Mission Control Jobs UI
# Open http://localhost:3000/jobs in your browser
# Username: test, Password: password
```

### Get Restaurant Data

```bash
# Get all restaurants
curl http://localhost:3000/restaurants

# Get specific restaurant with menus and items
curl http://localhost:3000/restaurants/1

# Get restaurant menus
curl http://localhost:3000/restaurants/1/menus

# Get restaurant menu items
curl http://localhost:3000/restaurants/1/menu_items
```

## Error Handling

The API provides consistent error responses:

- **400 Bad Request**: Invalid JSON format or missing required data
- **422 Unprocessable Content**: Validation errors or import failures
- **500 Internal Server Error**: Unexpected system errors

All error responses include:
- `success: false`
- `error`: Human-readable error message
- `details`: Technical error details when available

## Future Enhancements

The current implementation provides a solid foundation for:

- Authentication and authorization
- Rate limiting
- Caching strategies
- Bulk operations optimization
- Additional data validation rules
- Export functionality
- API versioning

## Quick Reference

### Common URLs
- **API Base**: http://localhost:3000
- **Mission Control Jobs**: http://localhost:3000/jobs (test/password)
- **PostgreSQL**: localhost:5433 (Docker) / localhost:5432 (Manual)

### Key Commands
```bash
# Docker
docker compose up          # Start application
docker compose down        # Stop application
docker compose logs -f     # View logs

# Rails
bin/rails server           # Start server
bin/rails console         # Open console
bin/rails routes          # View routes
bin/jobs                  # Start background jobs

# Testing
bundle exec rspec         # Run all tests
bundle exec rspec spec/models/  # Run specific tests
```

### Import Example
```bash
# Quick import test
curl -X POST http://localhost:3000/import \
  -H "Content-Type: application/json" \
  -d '{"restaurants":[{"name":"Test","menus":[{"name":"Lunch","menu_items":[{"name":"Burger","price":9.99}]}]}]}'
```

## Contributing

1. Follow the existing code style
2. Add tests for new functionality
3. Ensure all tests pass before submitting
4. Update documentation as needed

## License

This project is part of a technical challenge implementation.
