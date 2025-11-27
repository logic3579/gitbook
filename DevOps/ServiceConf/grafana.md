# Grafana

/etc/grafana/grafana.ini

```bash
[smtp]
enabled = true
host = 1.1.1.1
user = ""
password = ""
skip_verify = true
from_address = ""
[alerting]
enabled = true
execute_alerts = true
[rendering]
server_url = http://grafana-image-renderer:8081/render
callback_url = http://grafana/

```
