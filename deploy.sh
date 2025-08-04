#!/bin/bash

set -e

echo "🚀 Deploying Orbital CTF to production..."

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "❌ .env.production file not found!"
    echo "   Please copy .env.production.template to .env.production and configure it."
    exit 1
fi

# Load environment variables
export $(cat .env.production | grep -v '^#' | xargs)

# Validate required environment variables
if [ -z "$NEXTAUTH_SECRET" ]; then
    echo "❌ NEXTAUTH_SECRET is required in .env.production"
    exit 1
fi

if [ -z "$NEXTAUTH_URL" ]; then
    echo "❌ NEXTAUTH_URL is required in .env.production"
    exit 1
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL is required in .env.production"
    exit 1
fi

# Check if challenges directory exists
if [ ! -d "./challenges" ]; then
    echo "⚠️  Warning: ./challenges directory not found"
    echo "   Create this directory and add your CTF challenges"
    mkdir -p ./challenges
fi

# Build and start the application
echo "📦 Building the application..."
docker-compose --env-file .env.production build

echo "🔄 Stopping existing containers..."
docker-compose down

echo "🚀 Starting the application..."
docker-compose --env-file .env.production up -d

echo "✅ Deployment complete!"
echo "   Application is available at: $NEXTAUTH_URL"
echo "   View logs with: docker-compose logs -f"

# Wait for the application to be ready
echo "⏳ Waiting for application to be ready..."
sleep 10

# Health check
if curl -f -s "$NEXTAUTH_URL/api/config" > /dev/null; then
    echo "✅ Application is healthy and ready!"
else
    echo "❌ Application health check failed"
    echo "   Check logs with: docker-compose logs"
    exit 1
fi
