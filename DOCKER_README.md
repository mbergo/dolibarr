# Dolibarr Docker Setup

This Docker setup provides a complete containerized environment for running Dolibarr with all necessary services.

## Features

- **Dolibarr Application**: PHP 8.2 with Apache
- **MariaDB Database**: Version 11.1 for data storage
- **PHPMyAdmin** (optional): Database management interface
- **Maildev** (optional): Email testing server
- **Redis** (optional): Caching service
- **Custom Logo**: Pre-configured with WFS logo

## Prerequisites

- Docker Engine 20.10+ 
- Docker Compose v2.0+
- At least 2GB of free disk space
- Port 8080 available (or configure a different port)

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd dolibarr

# Copy environment file
cp .env.example .env

# Edit .env file with your preferred settings (optional)
nano .env
```

### 2. Start Services

```bash
# Start all services
docker-compose up -d

# Or build fresh and start
docker-compose up -d --build

# View logs
docker-compose logs -f dolibarr
```

### 3. Access Dolibarr

Open your browser and navigate to:
- **Application**: http://localhost:8080
- **Default Admin**: admin / admin123

## Service URLs

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Dolibarr | http://localhost:8080 | admin / admin123 |
| PHPMyAdmin* | http://localhost:8081 | dolibarr / dolibarr_pwd |
| Maildev* | http://localhost:8082 | - |

*Optional services - see "Using Optional Services" section

## Configuration

### Environment Variables

Edit the `.env` file to customize your installation:

```bash
# Database
MYSQL_DATABASE=dolibarr
MYSQL_USER=dolibarr
MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_root_password

# Dolibarr
DOLI_ADMIN_LOGIN=admin
DOLI_ADMIN_PASSWORD=your_admin_password
DOLI_URL_ROOT=http://localhost:8080

# Ports
WEB_PORT=8080
DB_PORT=3306

# Timezone
TZ=America/New_York
```

### Development Mode

To enable development mode with error display:

```bash
# In .env file
DOLI_DEV_MODE=1
```

## Docker Commands

### Basic Operations

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes (CAUTION: Deletes data!)
docker-compose down -v

# Restart services
docker-compose restart

# View logs
docker-compose logs -f [service-name]

# Execute commands in container
docker-compose exec dolibarr bash
docker-compose exec mariadb mysql -u root -p
```

### Using Optional Services

```bash
# Start with PHPMyAdmin
docker-compose --profile tools up -d

# Start with Maildev for email testing
docker-compose --profile tools up -d

# Start with Redis cache
docker-compose --profile cache up -d

# Start all optional services
docker-compose --profile tools --profile cache up -d
```

## File Structure

```
dolibarr/
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile             # Application container definition
├── docker-entrypoint.sh   # Container initialization script
├── .dockerignore         # Files to exclude from Docker build
├── .env.example          # Environment variables template
├── .env                  # Your environment configuration
├── htdocs/               # Dolibarr application files
├── conf/                 # Configuration files (auto-created)
├── documents/            # Document storage (auto-created)
└── custom/               # Custom modules directory (auto-created)
```

## Volumes

The setup uses the following volumes:

| Volume | Purpose | Container Path |
|--------|---------|---------------|
| `./htdocs` | Application code | `/var/www/html/htdocs` |
| `./conf` | Configuration | `/var/www/html/htdocs/conf` |
| `./custom` | Custom modules | `/var/www/html/htdocs/custom` |
| `documents` | File storage | `/var/www/documents` |
| `mariadb_data` | Database data | `/var/lib/mysql` |

## Database Access

### Using PHPMyAdmin

```bash
# Start PHPMyAdmin
docker-compose --profile tools up -d phpmyadmin

# Access at http://localhost:8081
```

### Using MySQL CLI

```bash
# Connect to database
docker-compose exec mariadb mysql -u dolibarr -p

# Backup database
docker-compose exec mariadb mysqldump -u root -p dolibarr > backup.sql

# Restore database
docker-compose exec mariadb mysql -u root -p dolibarr < backup.sql
```

## Email Testing with Maildev

```bash
# Start Maildev
docker-compose --profile tools up -d maildev

# Configure Dolibarr SMTP settings:
# SMTP Host: maildev
# SMTP Port: 25
# No authentication required

# View emails at http://localhost:8082
```

## Troubleshooting

### Permission Issues (Linux)

If you encounter permission issues on Linux:

```bash
# Get your user ID and group ID
id -u
id -g

# Add to .env file
HOST_USER_ID=1000  # Replace with your actual UID
HOST_GROUP_ID=1000 # Replace with your actual GID

# Restart containers
docker-compose down && docker-compose up -d
```

### Port Already in Use

If port 8080 is already in use:

```bash
# Change port in .env file
WEB_PORT=8090

# Restart
docker-compose down && docker-compose up -d
```

### Database Connection Issues

```bash
# Check database logs
docker-compose logs mariadb

# Test database connection
docker-compose exec dolibarr mysql -h mariadb -u dolibarr -p

# Recreate database volume (CAUTION: Deletes data!)
docker-compose down -v
docker-compose up -d
```

### Reset Installation

To completely reset and start fresh:

```bash
# Stop containers and remove volumes
docker-compose down -v

# Remove configuration
rm -rf conf/* documents/* custom/*

# Start fresh
docker-compose up -d --build
```

## Production Deployment

For production deployment:

1. **Use strong passwords** in `.env`
2. **Enable HTTPS** with a reverse proxy (nginx, traefik)
3. **Set DOLI_DEV_MODE=0** in `.env`
4. **Regular backups** of database and documents
5. **Monitor logs** for errors
6. **Update regularly** for security patches

### Example Production .env

```bash
DOLI_DEV_MODE=0
DOLI_URL_ROOT=https://erp.yourdomain.com
MYSQL_ROOT_PASSWORD=VeryStrongPassword123!
MYSQL_PASSWORD=AnotherStrongPassword456!
DOLI_ADMIN_PASSWORD=SuperSecureAdminPass789!
```

## Backup and Restore

### Backup

```bash
# Create backup directory
mkdir -p backups

# Backup database
docker-compose exec mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} dolibarr | gzip > backups/db_$(date +%Y%m%d_%H%M%S).sql.gz

# Backup documents
tar -czf backups/documents_$(date +%Y%m%d_%H%M%S).tar.gz documents/

# Backup configuration
tar -czf backups/conf_$(date +%Y%m%d_%H%M%S).tar.gz conf/
```

### Restore

```bash
# Restore database
gunzip < backups/db_TIMESTAMP.sql.gz | docker-compose exec -T mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} dolibarr

# Restore documents
tar -xzf backups/documents_TIMESTAMP.tar.gz

# Restore configuration
tar -xzf backups/conf_TIMESTAMP.tar.gz
```

## Support

For issues related to:
- **Docker setup**: Check this README and Docker logs
- **Dolibarr application**: Visit [Dolibarr Documentation](https://docs.dolibarr.org)
- **Database**: Check MariaDB logs with `docker-compose logs mariadb`

## License

Dolibarr is released under the GPLv3+ license. See the COPYING file for details.
