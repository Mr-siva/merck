# Outage checklist

1. `curl -v http://<ip>/health` - timeout (network) vs refused (nothing listening) vs 5xx (app).
2. AWS console: instance running? both status checks passing? public IP unchanged (no Elastic IP is used)?
3. Security group still allows tcp/80? Has my IP changed (SSH)?
4. SSH in: `systemctl status hello healthcheck.timer`
5. Logs: `journalctl -u hello -u healthcheck -n 100` and `journalctl -t healthcheck`
6. Resources: `df -h`, `free -m`, `ss -tlnp | grep :80`
7. Recover: `sudo systemctl restart hello`; if the host is broken, `terraform apply -replace=aws_instance.hello`.
8. Record cause and follow-up.
