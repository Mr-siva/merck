# MSD hello service

Small Python HTTP service (`/` message, `/health` JSON) deployed to one AWS free-tier EC2 instance with Terraform + cloud-init + systemd.

| Doc | What |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Request path diagram |
| [docs/operations.md](docs/operations.md) | Outage checklist |
| [docs/validation.md](docs/validation.md) | Evidence from the live deployment |
| [docs/ci-example.md](docs/ci-example.md) | Example CI run output |

## Repository layout
```
app/          server.py (stdlib only) + unit tests
deploy/       systemd units, healthcheck.sh, cloud-init template
terraform/    EC2 instance, security group, key pair
.github/      CI workflow
Dockerfile    local runs and CI smoke test only (the server does NOT use Docker)
```

## Prerequisites
AWS account (free tier), AWS CLI, Terraform >= 1.5, an SSH key (`ssh-keygen -t ed25519 -f ~/.ssh/msd_key`). Credentials come from your own AWS profile or environment (`export AWS_PROFILE=...`); **never commit them**.

## Local run
`make test && make run-local`, then `curl localhost:8080/health`. Or, with Docker running, `make docker-smoke`.

The Dockerfile exists for laptop testing and the CI smoke test. On EC2 the app runs natively under systemd: Ubuntu already ships Python 3, and systemd provides restart, start-on-boot and sandboxing without a container runtime on a 1 GB instance.

## Deploy
```
cd terraform
terraform init
terraform apply -var admin_cidr=$(curl -s https://checkip.amazonaws.com)/32
```
Outputs the URL and SSH command. Allow ~1 minute for cloud-init to finish. Omit `admin_cidr` to disable SSH entirely; `0.0.0.0/0` is rejected by a variable validation.

Firewall (security group): tcp/80 from anywhere; tcp/22 only from `admin_cidr`; nothing else inbound.

## Validate
```
IP=$(terraform -chdir=terraform output -raw public_ip)
curl -i http://$IP/            # 200, message
curl -i http://$IP/health      # 200, {"status": "ok"}
ssh -i ~/.ssh/msd_key ubuntu@$IP
  systemctl is-enabled hello healthcheck.timer   # enabled enabled
  sudo pkill -f '/opt/hello/[s]erver.py'         # systemd restarts it in ~2s
  sudo systemctl stop hello                      # health timer restarts it in ~30-40s
  journalctl -t healthcheck                      # "health check failed 3x ... restarting"
aws ec2 reboot-instances --instance-ids $(terraform -chdir=terraform output -raw instance_id)
curl http://$IP/health                           # back after ~30s, no manual step
```
`healthcheck.service` deliberately exits 1 after it restarts the app, so each recovery appears as a failed run (`systemctl --failed`) and can be alerted on. Exit 2 means the restart itself failed.

Evidence from a real run: [docs/validation.md](docs/validation.md).

## CI
`.github/workflows/ci.yml` runs on every push and PR:
- **app**: ruff lint, unit tests, Docker build + `/health` smoke test.
- **scripts-and-units**: shellcheck; installs the units exactly as cloud-init does, `systemd-analyze verify`, starts the service, runs the real health check, then stops the service and asserts the check detects it and restarts it.
- **terraform**: `fmt -check` and `validate`.

Deployment is not run from CI: no cloud credentials are stored in the repo. To add it, store AWS credentials as GitHub environment secrets with a required reviewer and add a `workflow_dispatch` job running `terraform apply`.

## Cleanup
```
cd terraform && terraform destroy -var admin_cidr=$(curl -s https://checkip.amazonaws.com)/32
```
Then confirm nothing is left: `aws ec2 describe-instances --filters Name=tag:Name,Values=msd-hello --query 'Reservations[].Instances[].State.Name'`.

## Troubleshooting
| Symptom | Likely cause | Check |
|---|---|---|
| `curl` times out | instance stopped, SG rule missing, wrong IP after replace | `terraform output`, instance state in console, SG inbound rules |
| connection refused | app not listening | `systemctl status hello`, `journalctl -u hello`, `ss -tlnp \| grep :80` |
| empty reply right after apply | cloud-init still running | `cloud-init status --wait`, `/var/log/cloud-init-output.log` |
| SSH times out | your public IP changed | `curl https://checkip.amazonaws.com`; re-apply with new `admin_cidr` |
| SSH `Permission denied (publickey)` | wrong key, or default user missing | `ssh -i ~/.ssh/msd_key ubuntu@...`; see validation notes |
| `healthcheck.service` failed | it restarted the app (expected) or restart failed | `journalctl -t healthcheck` |

## Assumptions and limitations
- Single instance in the default VPC: no high availability, and the public IP changes if the instance is replaced (no Elastic IP, to stay free).
- Plain HTTP, no TLS. Production: ALB + ACM certificate, or Caddy with Let's Encrypt.
- The health check runs on the same host, so it cannot detect a dead instance. Production: external uptime check or CloudWatch alarm on status checks.
- Terraform state is local. Production: S3 backend with locking.
- Outbound traffic is unrestricted (needed for package updates); could be narrowed.
- SSH is restricted by source IP only; AWS SSM Session Manager would remove port 22 entirely.
- Free-tier eligibility depends on account age and region (`t3.micro` in us-east-1 here).
