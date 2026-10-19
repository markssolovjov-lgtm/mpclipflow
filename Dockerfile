# MP ClipFlow — образ приложения (API + веб-интерфейс + фоновые обработчики).
# Created by MP Production.
FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
COPY packages/shared/package.json packages/shared/
COPY apps/server/package.json apps/server/
COPY apps/web/package.json apps/web/
COPY apps/server/prisma apps/server/prisma
RUN npm ci --ignore-scripts && npx -w @clipflow/server prisma generate
COPY . .
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
# Системный FFmpeg (с libx264); ffmpeg-static в образе не используется.
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg openssl ca-certificates && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production FFMPEG_PATH=/usr/bin/ffmpeg FFPROBE_PATH=/usr/bin/ffprobe DATA_DIR=/app/data PORT=8080
COPY --from=build /app /app
EXPOSE 8080
VOLUME ["/app/data"]
CMD ["sh", "-c", "npm run db:deploy -w @clipflow/server && node apps/server/dist/main.js"]
