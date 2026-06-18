FROM nginx:1.27-alpine

# Pull in security-patched Alpine packages rather than whatever was baked
# into the base image when it was last published
RUN apk update && apk upgrade --no-cache

COPY . /usr/share/nginx/html