FROM wunsh/alpine-elm:latest
RUN apk add --update nodejs nodejs-npm
COPY ./ /app
WORKDIR /app
RUN elm make src/client/elm/Main.elm
RUN npm install
RUN npm run build

FROM nginx
RUN mkdir /app
COPY --from=0 /app/dist /app
COPY nginx.conf /etc/nginx/nginx.conf
