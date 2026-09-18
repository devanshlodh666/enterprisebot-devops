FROM node:22.19.0-bookworm-slim AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev


FROM node:22.19.0-bookworm-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080

COPY --from=dependencies /app/node_modules ./node_modules
COPY package.json ./
COPY app.js ./

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid 10001 --create-home appuser \
    && chown -R appuser:appgroup /app

USER 10001

EXPOSE 8080

CMD ["node", "app.js"]