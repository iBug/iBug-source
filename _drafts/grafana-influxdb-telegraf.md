---
title: "Infrastructure Monitoring with Grafana, InfluxDB, and Telegraf"
tags: server
redirect_from: /p/58
---

In a recent contest, we were tasked with running various workloads on a server cluster under certain constraints like total power consumption. Due to the immediacy of these monitored data, short intervals (&lt;= 5s) and an intuitive visualization were integral. In previous iterations of the contest, our team came up with all kinds of makeshift solutions that suffered from all kinds of problems like inaccuracy, lack of data persistence and poor visualization. So this year I decided to replicate my server monitoring setup.

This monitoring system consists of three main components:

- [Grafana](https://grafana.com/) is a visualization tool that can be used to create dashboards with various data sources.
- [InfluxDB](https://www.influxdata.com/) is a time-series database that stores data in a time-ordered fashion.
- [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) is a data collector that can be used to collect data from various sources and send it to InfluxDB.

For historical reasons, I opt for InfluxDB 1.8 instead of the newer InfluxDB 2.x. The newer version is more powerful and feature-rich, at the expense of a more complicated setup process and a steeper learning curve.

Installation of all three pieces is pretty straightforward following their official documentation ([Grafana](https://grafana.com/docs/grafana/latest/getting-started/), [InfluxDB](https://docs.influxdata.com/influxdb/v1.8/introduction/get-started/) and [Telegraf](https://docs.influxdata.com/telegraf/latest/get-started/)). In addition, I reuse my existing MariaDB database to for Grafana.

Due to the nature of Grafana, a read-only user is required for InfluxDB. This is done with two InfluxQL statements, similar to SQL:

```sql
CREATE USER grafana WITH PASSWORD 'password';
GRANT READ ON systems TO grafana;
```

This InfluxDB is configured as a "Data Source" through the Grafana web interface, while the MySQL (MariaDB) database should be specified in `grafana.ini`.

There's also a nice thing about Grafana: it's vast [repository](https://grafana.com/grafana/dashboards/) of ready-to-use dashboards. I pick [this one](https://grafana.com/grafana/dashboards/928-telegraf-system-dashboard/) for my system.

