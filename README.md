InfluxDB -> Tasks

```flux
import "experimental/prometheus"

option task = {name: "Scrape Weather", every: 5m}

prometheus.scrape(url: "https://wttr.in/?format=p1")
    |> to(bucket: "weather")
```
