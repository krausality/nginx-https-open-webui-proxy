Alright, so i needed an https proxy for enabling the voice input feature on my smartphone, which connects to a local server Open WebUI running on windows pc.
Ollama via the windows installer was already setup previous to this.

This was my initial nginx setup:

`mkdir nginx_proxy_server`
`cd nginx_proxy_server`

1. Create the `Dockerfile`:

```Dockerfile
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
```

2. Create the `nginx.conf` file:

```nginx
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost 192.168.178.102;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name localhost 192.168.178.102;

        ssl_certificate /etc/nginx/cert.crt;
        ssl_certificate_key /etc/nginx/cert.key;

        location / {
            proxy_pass http://host.docker.internal:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

3. Create `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  nginx-ssl-proxy:
    build: .
    ports:
      - "80:80"
      - "443:443"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: always  # This is the equivalent of --restart always

```

4. Build the container:

```powershell
docker-compose up -d --build
```

5. Ensure your Open WebUI container is running:

```powershell
docker run -d -p 3000:8080 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

This solved my inital microphone problem BUT **now i had issues with the Answer streaming**.

So all i did was the following:

1. Modify the nginx.conf located in the nginx_proxy_server to the following version:

```
events {
    worker_connections 1024;
}

http {

    map $http_accept $sse_content_type {
        "~*text/event-stream" text/event-stream;
        default application/json;
    }
    server {
        listen 80;
        server_name localhost 192.168.178.102;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;
        server_name localhost 192.168.178.102;

        ssl_certificate /etc/nginx/cert.crt;
        ssl_certificate_key /etc/nginx/cert.key;

        location / {
            proxy_pass http://host.docker.internal:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;

            # SSE support
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;
            proxy_set_header Content-Type $sse_content_type;

            # Increase timeouts for long-running requests
            proxy_read_timeout 24h;
            proxy_send_timeout 24h;
            keepalive_timeout 24h;
        }
    }
}
```

2. Rebuild and restart the container:

```
docker-compose down
docker-compose up -d --build
```



