# Sense to InfluxDB

This simple script will scrape the [Sense](https://sense.com) api and import some metrics into an influxdb bucket, for use with grafana. Obviously this is predicated on you having a sense energy meter and an account.

## Setup

I just use docker compose, so filling in the values in `.env` automatically works. Not using docker? Pretty easy:


```bash
pip install -r requirements
python main.py
```

## Add some weather info

In the InfluxDB UI, go to Tasks and created a new task with this script:

```flux
import "experimental/prometheus"

option task = {name: "Scrape Weather", every: 5m}

prometheus.scrape(url: "https://wttr.in/?format=p1")
    |> to(bucket: "weather")
```
