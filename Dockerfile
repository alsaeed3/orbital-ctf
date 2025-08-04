# Build stage
FROM node:20-alpine AS builder

# Install pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy project files
COPY . .

# Generate Prisma client
RUN pnpm prisma:generate

# Build the Next.js application
RUN pnpm run build

# Production stage
FROM node:20-alpine AS runner
WORKDIR /app

# Install pnpm
RUN corepack enable pnpm

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 --ingroup nodejs --disabled-password --shell /sbin/nologin nextjs

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Copy built files from builder stage
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma

# Ensure necessary directories exist with proper permissions
RUN mkdir -p public/uploads /challenges
RUN chown -R nextjs:nodejs public/uploads /challenges

# Switch to non-root user
USER nextjs

# Expose the port the app runs on
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Initialize database and run the app
CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma db seed; node .next/standalone/server.js"]
