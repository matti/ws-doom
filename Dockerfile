FROM node:12.18.3-alpine3.12
ENV PORT=8080
ENV DISPLAY=:0

RUN apk add --no-cache \
  bash \
  xvfb xdpyinfo x11vnc \
  nodejs git \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  chocolate-doom

COPY --from=mattipaksula/doom1wad /doom1.wad /

WORKDIR /opt
RUN git clone https://github.com/novnc/websockify-js.git \
  && cd websockify-js/websockify && npm install

WORKDIR /app

COPY app .
ENTRYPOINT [ "/app/entrypoint.sh" ]
