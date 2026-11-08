# --- Stage 1: Build & Dependency Resolution ---
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

# Install dependencies needed for compiling native addons if required
RUN apk add --no-cache python3 make g++

# Copy package files first to leverage Docker layer caching
COPY package*.json ./
RUN npm ci --only=production

# Copy source code and build assets if applicable
COPY . .
# RUN npm run build # Uncomment if using TypeScript/bundlers

# --- Stage 2: Minimal Runtime Image ---
FROM gcr.io/distroless/nodejs20-debian12:nonroot
WORKDIR /usr/src/app

# Copy production node_modules and built source code from builder
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/src ./src

# Expose internal port and drop privileges completely
EXPOSE 3000
USER nonroot

ENV NODE_ENV=production
CMD ["src/app.js"]
