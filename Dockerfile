# Stage 1: Base Image
# Use a base image with a recent version of Node.js and Alpine for a small footprint.
FROM node:22.12.0-alpine AS base

# Install dependencies needed for Payload CMS and Next.js
# libc6-compat is often needed for Node.js on Alpine
RUN apk add --no-cache libc6-compat

# Set the working directory for the application
WORKDIR /app

# Stage 2: Install Dependencies
FROM base AS deps
# Copy only the necessary files for dependency installation
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./

# Install dependencies based on the lockfile
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm install --legacy-peer-deps; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Stage 3: Build the Application
FROM base AS builder
WORKDIR /app

# Copy installed node_modules from the `deps` stage
COPY --from=deps /app/node_modules ./node_modules

# Copy the rest of your application source code
COPY . .

# Set environment variables for the build process (if needed)
# Replace these with your actual environment variables
ARG PAYLOAD_SECRET
ARG DATABASE_URI
ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
ENV DATABASE_URI=$DATABASE_URI

# Build the Payload CMS application
RUN \
  if [ -f yarn.lock ]; then yarn run build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Stage 4: Production Runtime Image
FROM base AS runner
WORKDIR /app

# Set the environment to production
ENV NODE_ENV production

# --- START of the solution for Railway volume permissions ---

# Create a system user and group with the UID and GID that own the Railway volume.
# Replace '65534' with the actual UID/GID you found.
ARG RAILWAY_USER_UID=65534
ARG RAILWAY_USER_GID=65534
RUN addgroup --system --gid ${RAILWAY_USER_GID} railwayusergroup
RUN adduser --system --uid ${RAILWAY_USER_UID} --ingroup railwayusergroup railwayuser

# Set the correct permissions for the .next build output directory
# This is an internal directory, so we'll chown it to our new user.
RUN mkdir .next
RUN chown railwayuser:railwayusergroup .next

# Copy application files from the builder stage
# We'll chown them to the correct user directly during the copy operation.
COPY --from=builder /app/public ./public
COPY --from=builder --chown=railwayuser:railwayusergroup /app/.next/standalone ./
COPY --from=builder --chown=railwayuser:railwayusergroup /app/.next/static ./.next/static

# Switch to the non-root user that matches the volume owner
# This is the key step to avoid "Operation not permitted" errors.
USER railwayuser

# --- END of the solution for Railway volume permissions ---

# Expose the port your application listens on
EXPOSE 3000

# Set the port environment variable
ENV PORT 3000

# Start the application
# We no longer need an entrypoint script because permissions are handled by the user switch.
CMD HOSTNAME="0.0.0.0" node server.js
