FROM node:20-alpine AS deps
WORKDIR /app

COPY package*.json ./
RUN npm install


FROM node:20-alpine AS build
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build


FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

RUN rm -rf ./*
COPY --from=build /app/build ./
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

HEALTHCHECK CMD wget -qO- http://localhost/ || exit 1

USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]