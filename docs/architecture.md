# Architecture / request path

```mermaid
flowchart LR
  U[Client] -->|HTTP :80| SG[Security group<br/>80 open, 22 admin IP only]
  SG --> EC2[EC2 t3.micro Ubuntu 24.04]
  subgraph EC2
    S[systemd: hello.service<br/>python server.py, user hello, Restart=always]
    T[systemd timer: healthcheck every 30s]
    T -->|curl 127.0.0.1/health| S
    T -->|3 failures: systemctl restart| S
  end
```

Request: client -> internet -> security group (allows tcp/80) -> instance -> python process (non-root, bound via CAP_NET_BIND_SERVICE).
Reboot: systemd starts `hello.service` and `healthcheck.timer` (both enabled by cloud-init).
