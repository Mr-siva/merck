# MSD hello service

Small Python HTTP service (`/` message, `/health` JSON) deployed to one AWS free-tier EC2 instance with Terraform + cloud-init + systemd. See [architecture](docs/architecture.md) and [operations note](docs/operations.md).

## Prerequisites
AWS account (free tier), AWS CLI, Terraform >= 1.5, an SSH key (`ssh-keygen -t ed25519 -f ~/.ssh/msd_key`). Credentials come from your own AWS profile or environment; **never commit them**.

## Local run
`make test && make run-local`, then `curl localhost:8080/health`. Or `make docker-smoke`.

## Deploy
```
cd terraform
terraform init
terraform apply -var admin_cidr=$(curl -s https://checkip.amazonaws.com)/32
```
Outputs the URL. Omit `admin_cidr` to disable SSH entirely.

## Validate
- `curl http://<ip>/` and `/health` return 200.
- Reboot: `aws ec2 reboot-instances ...`; service returns by itself (systemd enabled).
- Kill test: `sudo pkill -f server.py` -> restarted within ~2s by `Restart=always`; stop it with `systemctl stop hello` and the health timer restarts it within ~30-40s (`journalctl -t healthcheck`).

Evidence from a real run: [docs/validation.md](docs/validation.md).

## Cleanup
`terraform destroy -var admin_cidr=...`

## Troubleshooting
| Symptom | Check |
|---|---|
| curl times out | security group / instance state / cloud-init still running (`cloud-init status`) |
| connection refused | `systemctl status hello`, `journalctl -u hello` |
| SSH times out | your IP changed; re-apply with new `admin_cidr` |

## Limitations
Single instance (no HA), plain HTTP (no TLS), local Terraform state, health check runs on the same host so it cannot detect host-level failure. Production would add an ALB + ACM, remote state and external monitoring. Deploy is manual; CI validates only, as no cloud credentials are stored in the repo.
