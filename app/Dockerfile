FROM node:16
WORKDIR /app
RUN npm init -y
RUN npm install express
COPY package*.json ./
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]