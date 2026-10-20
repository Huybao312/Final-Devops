# Todo Task Manager — DevOps Week 1

Flask + SQLite task manager with create, edit, delete, completion toggle, and a `GET /health` health check.

## Local development

```bash
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
./venv/bin/python app.py
```

Open `http://localhost:5000`; health check: `curl -f http://localhost:5000/health`.

## Ubuntu deployment

The checked-in service assumes the repository lives at `/opt/todo-task-manager` and runs as `www-data`.

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip nginx curl
sudo mkdir -p /opt/todo-task-manager
sudo chown -R "$USER":www-data /opt/todo-task-manager
# Copy/clone this repository into /opt/todo-task-manager, then:
cd /opt/todo-task-manager
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
sudo chown -R www-data:www-data /opt/todo-task-manager
sudo install -m 0644 systemd/flaskapp.service /etc/systemd/system/flaskapp.service
sudo install -m 0644 nginx/flaskapp /etc/nginx/sites-available/flaskapp
sudo ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl daemon-reload
sudo systemctl enable --now flaskapp
sudo nginx -t
sudo systemctl reload nginx
curl -f http://localhost/health
```

Run `./scripts/deploy.sh` for subsequent deployments. It pulls from `origin` when configured, installs dependencies, restarts `flaskapp`, and checks `http://localhost/health`.
