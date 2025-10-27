FROM node:18-alpine

WORKDIR /usr/src/app

COPY app/package.json ./
RUN npm install --production

COPY app/ ./

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]
