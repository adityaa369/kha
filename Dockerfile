FROM node:18-alpine

WORKDIR /app

# Copy package files from the server subdirectory
COPY server/package*.json ./

RUN npm install

# Copy the rest of the server code
COPY server/ .

EXPOSE 5000

CMD ["npm", "start"]
