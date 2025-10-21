# 🚀 Quick Start - Dolibarr with Docker

## One-Command Start

```bash
./start.sh
```

That's it! The script will:
- ✅ Check Docker installation
- ✅ Set up environment
- ✅ Build and start all services
- ✅ Display access URLs

## Access Dolibarr

After startup, access at:
- **URL**: http://localhost:8080
- **Username**: admin
- **Password**: admin123

## Alternative: Using Make

```bash
# Start services
make up

# Start with tools (PHPMyAdmin, Maildev)
make up-tools

# View logs
make logs

# Stop services
make down
```

## Alternative: Using Docker Compose Directly

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f
```

## Need Help?

- Full documentation: See `DOCKER_README.md`
- Available commands: Run `make help`
- Check status: Run `make status`

## Your Custom Logo

The WFS logo has been applied throughout the application! 🎨
