FROM node:20-alpine AS deps
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

FROM deps AS test
ENV NODE_ENV=development
RUN npm install
COPY . .
RUN npm test

FROM node:20-alpine AS production
WORKDIR /app

ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.title="backend-service"

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=deps /app/node_modules ./node_modules
COPY . .

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/api/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

USER appuser

EXPOSE 4000

CMD ["node", "server.js"]