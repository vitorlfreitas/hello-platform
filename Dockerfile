# Stage 1: Build stage — uses Node.js 25 Alpine for a lightweight build environment
FROM node:25-alpine AS builder

# Set the working directory inside the container to /app
WORKDIR /app

# Copy package.json and package-lock.json into the container
# (only these two files first to leverage Docker layer caching for dependencies)
COPY package*.json ./

# Install all dependencies (including dev dependencies needed for building)
RUN npm ci

# Copy the entire source code into the container
COPY . .

# Compile TypeScript source files into JavaScript in the dist/ folder
RUN npm run build

# Stage 2: Production stage — fresh lightweight image with only runtime dependencies
FROM node:25-alpine

# Set the working directory inside the production container
WORKDIR /app

# Copy package.json and package-lock.json for dependency installation
COPY package*.json ./

# Install only production dependencies (no dev tools, smaller image)
RUN npm ci --only=production

# Copy the compiled JavaScript output from the build stage into this image
COPY --from=builder /app/dist ./dist

# Create a dedicated non-root group (GID 1001) and user (UID 1001) for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Transfer ownership of /app to the nodejs user so it can read/write files
RUN chown -R nodejs:nodejs /app

# Switch the container process to the non-root user (avoids running as root)
USER nodejs

# Declare that the container listens on port 3000 (informational; does not publish the port)
EXPOSE 3000

# Define a health check that polls /health every 30s; exits non-zero if the response is not 200
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Default command: start the compiled application entry point
CMD ["node", "dist/index.js"]
