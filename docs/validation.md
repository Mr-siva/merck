# Validation evidence

Run against the deployed instance (Ubuntu 24.04, t3.micro, us-east-1) on 2026-11-08.

| Test | Action | Result |
|---|---|---|
| Endpoints | `curl /`, `/health`, `/nope` | 200 `Hello from the MSD platform service!`, 200 `{"status": "ok"}`, 404 |
| Boot config | `systemctl is-enabled hello healthcheck.timer` | `enabled enabled` |
| Least privilege | `ps -o user= -C python3` | `hello` (non-root), listening on `0.0.0.0:80` |
| Process crash | `pkill` the python process | `hello` active again within 4s (`Restart=always`) |
| Hung/stopped service | `systemctl stop hello` | Health timer recovered it in ~35s; journal: `health check failed 3x ... restarting hello.service`, then `restarted hello.service` |
| Reboot | `aws ec2 reboot-instances` | `/health` back after ~30s with no manual step; `uptime: up 0 minutes`, both units `active` |

## Issue found and fixed during validation
First deploy used a cloud-init `users:` block without `- default`, which removed the stock `ubuntu` user, so SSH key login failed although HTTP worked. Fixed by adding `- default`; instance was replaced via Terraform (`user_data_replace_on_change`).
