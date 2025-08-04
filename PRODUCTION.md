# Production Deployment Guide

This guide covers deploying Orbital CTF to production.

## Prerequisites

- Docker and Docker Compose installed
- Domain name configured (optional but recommended)
- SSL certificate (recommended for production)

## Production Setup

### 1. Environment Configuration

1. Copy the production environment template:
   ```bash
   cp .env.production.template .env.production
   ```

2. Edit `.env.production` with your production values:
   ```bash
   NEXTAUTH_SECRET="generate-a-secure-32-character-secret"
   NEXTAUTH_URL="https://your-domain.com"
   DATABASE_URL="file:./prod.db"  # or PostgreSQL URL
   ```

### Important: Standalone Mode
This application is configured with Next.js standalone output for optimal production performance. This means:
- The `pnpm start` command runs `node .next/standalone/server.js` instead of `next start`
- All dependencies are bundled into the standalone output for faster startup
- Perfect for containerized deployments with minimal overhead

### 2. Security Considerations

- **NextAuth Secret**: Generate a secure random string:
  ```bash
  openssl rand -base64 32
  ```
- **Database**: Consider using PostgreSQL for production instead of SQLite
- **SSL/TLS**: Use a reverse proxy (nginx) with SSL certificates
- **File Uploads**: Configure proper upload limits and validation

### 3. Database Options

#### SQLite (Simple, not recommended for high-traffic)
```env
DATABASE_URL="file:./prod.db"
```

#### PostgreSQL (Recommended for production)
1. Uncomment the PostgreSQL service in `docker-compose.yml`
2. Update your `.env.production`:
   ```env
   DATABASE_URL="postgresql://orbital_ctf:your_password@postgres:5432/orbital_ctf"
   POSTGRES_USER=orbital_ctf
   POSTGRES_PASSWORD=your_secure_password
   ```

### 4. Challenges Setup

1. Create a `challenges` directory in the project root
2. Add your CTF challenge files and configurations
3. The challenges will be automatically ingested on startup

### 5. Deployment

#### Quick Deployment
```bash
./deploy.sh
```

#### Manual Deployment
```bash
# Build the application
docker-compose build

# Start the services
docker-compose up -d

# Check logs
docker-compose logs -f
```

#### Local Production Build Testing
```bash
# Build the application
pnpm run build

# Run in production mode (standalone)
pnpm run start

# Or run with Next.js built-in server (not recommended for production)
pnpm run start:next
```

### 6. Reverse Proxy Setup (Recommended)

Create an nginx configuration for SSL termination:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # File upload size limit
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
}
```

## Monitoring and Maintenance

### Health Checks
The application includes built-in health checks accessible at `/api/config`.

### Logs
```bash
# View application logs
docker-compose logs -f app

# View all service logs
docker-compose logs -f
```

### Database Backups

#### SQLite
```bash
# Backup
docker-compose exec app sqlite3 /app/prisma/prod.db ".backup backup-$(date +%Y%m%d).db"

# Restore
docker-compose exec app sqlite3 /app/prisma/prod.db ".restore backup-YYYYMMDD.db"
```

#### PostgreSQL
```bash
# Backup
docker-compose exec postgres pg_dump -U orbital_ctf orbital_ctf > backup-$(date +%Y%m%d).sql

# Restore
docker-compose exec -T postgres psql -U orbital_ctf orbital_ctf < backup-YYYYMMDD.sql
```

### Updates

1. Pull the latest code
2. Rebuild and restart:
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

## Troubleshooting

### Common Issues

1. **Build fails**: Check that all environment variables are set correctly
2. **Database connection errors**: Verify DATABASE_URL format and database accessibility
3. **Authentication issues**: Ensure NEXTAUTH_SECRET and NEXTAUTH_URL are correctly configured
4. **File upload issues**: Check volume mounts and permissions

### Debug Mode
To run with debug logging:
```bash
docker-compose logs -f app
```

## Performance Optimization

1. **Use PostgreSQL**: Better performance than SQLite for concurrent users
2. **Enable caching**: Configure Redis for session storage (optional)
3. **CDN**: Use a CDN for static assets in high-traffic scenarios
4. **Resource limits**: Set appropriate memory and CPU limits in docker-compose.yml

## Security Checklist

- [ ] Strong NEXTAUTH_SECRET generated
- [ ] HTTPS enabled with valid SSL certificate
- [ ] Database credentials secured
- [ ] File upload validation enabled
- [ ] Regular security updates applied
- [ ] Backup strategy implemented
- [ ] Monitoring and logging configured
