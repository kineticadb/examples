<h3 align="center" style="margin:0px">
    <img width="200" src="../_assets/images/logo_purple.png" alt="Kinetica Logo"/>
</h3>
<h5 align="center" style="margin:0px">
    <a href="https://www.kinetica.com/">Website</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.2/">Docs</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.2/api/">API Docs</a>
    <span> | </span>
    <a href="https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg">Community Slack</a>   
</h5>
<p align = "center">
 <img src="https://img.shields.io/badge/tested-%3E=v7.2.2.3-green"></img>  <img src="https://img.shields.io/badge/time-20 mins-blue"></img>
</p>
<h1>
Real‑Time Sensor Alerts with Python + SQL in Kinetica
</h1>

This tutorial shows how to pair IoT telemetry with live weather data inside Kinetica using Python UDFs and SQL, turning context‑poor metrics into actionable alerts that hit Slack in real time.

1. Simulated sensor stream – a Python UDF publishes temperature, humidity, voltage, and vibration metrics every 5 minutes.
2. Live weather lookup – another UDF pulls current conditions from OpenWeather and stores them in Kinetica.
3. Context‑aware anomaly view – SQL joins both feeds with an *ASOF* window and flags temperature anomalies.
4. Real‑time notifications – a CREATE STREAM pushes new alerts to a webhook (or apps like Slack).

# Prerequisites

- Kinetica v7.2.3+ with enable_procs = true
- A Python environment named `` (see notebook for creation)
- Two scripts uploaded to KIFS under `/udfs/`\
  - simulate_sensor_data.py
  - weather_data_enrich.py
- An OpenWeather API key

# Try it yourself

All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica) instructions, if you don't have an instance of Kinetica available.

# Support

For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

# Contact Us

- Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
- Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
- Email us: [support@kinetica.com](mailto:support@kinetica.com)
- Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
