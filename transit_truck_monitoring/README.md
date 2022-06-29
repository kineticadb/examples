<h1 align = "center">
Real time IoT monitoring system for transit trucks
<br>
<img src="https://img.shields.io/badge/tested-%3E=v7.1.6-green"></img>  <img src="https://img.shields.io/badge/time-30 mins-blue"></img>
</h1>
<h3 align="left">

</h3>
<h6 align="center">Demo Video 👇🏼</h6>
<h3 align="center">

[![Transit truck monitoring](https://img.youtube.com/vi/eA7YcRD1UVI/0.jpg)](https://www.youtube.com/watch?v=eA7YcRD1UVI)
</h3>

Interrupted or incorrect temperature control during transit is the cause of over one-third of the world’s food spoilage. This represents billions of dollars in losses every year.
<h3 align="center">
   <img src="https://assets.website-files.com/5e997655a5b30c6a2ba6626c/5e9982df64d694568de7cebd_5cda5d509462d99c4643f3a0_Food%2520waste-p-1600.jpeg" width="300px"></img>

</h3>

It is therefore important to monitor the conditions inside the truck at all times so that any shift from ideal storage conditions can be immediately flagged and corrected. But this is easier said than done.

A real time monitoring system for cold transit requires you to combine different streaming data sources that record things like GPS, pressure, temperature etc. 

But the challenge  is that this information is often coming from different sensors which record and send this information out at different points in time.  So combining them is not a straightforward task.

We solve this by performing an inexact ASOF join that is kept updated in real time using a materialized view. 

```sql
CREATE OR REPLACE MATERIALIZED VIEW transit_trucks.vehicle_analytics 
REFRESH EVERY 5 SECONDS AS 
SELECT
   vl.TRACKID AS vehicle_id,
   DATETIME(vm.ts) as DATETIME,
   vm.pressure 
FROM
   transit_trucks.vehicle_locations vl 
   INNER JOIN
      transit_trucks.vehicle_metrics vm 
      ON vl.TRACKID = vm.id 
      AND vl.TIMESTAMP = vm.ts
```
With just a single SQL statement we get an always on up to date view of cold storage metrics for different transit trucks. This view is then plugged into downstream alerting and decisioning systems.

## How to get started
If you already have an instance of Kinetica, you can simply upload the json file for the workbook in this folder into Kinetica. The demo, shows you how to implement security using both SQL and the UI. The workbook will show you how to do that with just some easy SQL code.

Follow the instructions [here](https://github.com/kineticadb/examples#install-kinetica) if you do not have an instance of Kinetica.

## For Help
Join our [community slack channel](https://join.slack.com/t/kinetica-community/shared_invite/zt-12vqzfkqo-fPi760XCuL0Ub1fxCzRIWQ) or search our [documentation](https://docs.kinetica.com/7.1/azure/)
