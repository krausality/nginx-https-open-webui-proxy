FROM nginx:alpine

# Install OpenSSL
RUN apk add --no-cache openssl

# Generate self-signed certificate for both localhost and IP
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt -subj "/CN=localhost" -addext "subjectAltName = IP:192.168.178.102, DNS:localhost"

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose ports
EXPOSE 80 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
