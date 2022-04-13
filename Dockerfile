FROM nginx:1.21.6-alpine

# instead of copy, we mount files via volume
#COPY k8s/nginx-basic-auth/cm-index.html /usr/share/nginx/html/index.html

# port exposed
EXPOSE 80/tcp




