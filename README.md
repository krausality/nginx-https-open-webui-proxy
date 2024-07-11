Alright, so i needed an https proxy for enabling the voice input feature on my smartphone, which connects to a local server Open WebUI running on windows pc.
Ollama via the windows installer was already setup previous to this.

This was my initial nginx setup:

`mkdir nginx_proxy_server`
`cd nginx_proxy_server`

1. Create the `Dockerfile`:

```
File Dockerfile provided in this repo
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

```
File docker-compose.yml provided in this repo
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
File nginx.conf provided in this repo
```

2. Rebuild and restart the container:

```
docker-compose down
docker-compose up -d --build
```



