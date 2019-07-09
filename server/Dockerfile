FROM node:10
COPY ./ /app
WORKDIR /app
RUN npm install --production
RUN npm run build
CMD npm start