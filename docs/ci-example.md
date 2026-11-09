# Example CI run

Run: https://github.com/Mr-siva/msd/actions/runs/42561693701 (push to `main`, 2026-11-09). Result: **success**.

```
✓ main ci · 42561693701
JOBS
✓ app in 13s
✓ scripts-and-units in 9s
✓ terraform in 15s
```

## Key log lines

**app**: lint, tests, container smoke test
```
ruff check app            -> All checks passed!
python -m unittest -v     -> Ran 3 tests ... OK
docker run + curl /health -> {"status": "ok"}
curl /                    -> Hello from the MSD platform service!
```

**scripts-and-units**: the configuration check. Installs the units exactly as cloud-init does on EC2, verifies them, then exercises the health check on both paths.
```
shellcheck deploy/healthcheck.sh       -> no findings
systemd-analyze verify (3 units)       -> no errors
healthcheck.sh with service running    -> healthcheck: OK
systemctl stop hello; healthcheck.sh   -> healthcheck exit code: 1 (1 = restarted)
journal:
  healthcheck[2430]: health check failed 3x for http://127.0.0.1:80/health; restarting hello.service
  healthcheck[2433]: restarted hello.service
systemctl is-active hello              -> active
```

**terraform**
```
terraform fmt -check -recursive -> no changes
terraform validate              -> Success! The configuration is valid.
```

## What CI does not do
It does not deploy. No cloud credentials are stored in the repository; deployment is run manually with `terraform apply` (see README). Evidence from the live deployment is in [validation.md](validation.md).
