FROM node:18-slim
WORKDIR /app
RUN npm init -y
RUN npm install express @aws-sdk/client-secrets-manager pg
COPY package*.json ./
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
