# Kiến trúc cuối

![Architecture](architecture.svg)

```mermaid
flowchart LR
  Dev[Developer] --> Git[GitHub repository]
  Git --> CI[GitHub-hosted build and PostgreSQL tests]
  CI --> Runner[Self-hosted VM runner]
  Runner --> App[App container :5000 loopback]
  Client[Browser] --> Nginx[Nginx host :80]
  Nginx --> App
  App --> DB[(PostgreSQL :5432 internal)]
  DB --> Volume[(Named volume)]
  Node[Node Exporter VM CPU/RAM] --> Prom[Prometheus loopback :9090]
  Probe[Blackbox via Nginx health] --> Prom
  Prom --> Graf[Grafana loopback :3000]
  DB --> Backup[Private pg_dump archive and SHA256]
  Backup --> Restore[(Isolated restore verification DB)]
```

Production Compose project và monitoring Compose project độc lập. Backend DB network internal; app nối frontend/backend; proxy host chỉ gọi published loopback. Exporters dùng host namespace để số liệu là của VM Linux, không phải máy Mac. Grafana/Prometheus không publish ra LAN; quản trị đi qua SSH tunnel. Host PostgreSQL tuần 1 nếu còn chỉ phục vụ rollback và không phải DB của app hiện tại.

## Quyết định và đánh đổi

- PostgreSQL thay SQLite vì có service/network/role riêng và backup định dạng rõ ràng.
- Compose phù hợp một VM; không cần Kubernetes cho rubric này.
- Self-hosted runner có đường tới VM private nhưng đòi hỏi bảo vệ repo/workflow và quyền Docker.
- Blackbox đo đường Nginx → app → DB ở endpoint health, không chỉ kiểm tra process còn tồn tại.
- Restore vào DB riêng giữ an toàn dữ liệu hiện có; production cutover cần kế hoạch riêng.
- `/version` là SHA image build, giúp đối chiếu commit/run/app; nó không chứng minh toàn bộ host package giống nhau.
