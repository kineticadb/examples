<h1 align = "center">
A simple illustration of Geofencing with Kinetica
<br>
<img src="https://img.shields.io/badge/tested-%3E=v7.7.2-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</h1>
This workbook illustrates the concept of geofencing using Kinetica.

## What is geofencing?
Geofencing is the ability to classify an object as being inside a defined geographical boundary. 

## What are some common use cases for geofencing?
The most common use case for geofencing is to trigger an event (for instance an alert) when an object is inside or outside the fence. Some examples are listed below.

1. Triggering an alert when a vehicle enters a restricted zone,
2. Alerting a customer when a delivery truck carrying a package is within a certain distance from their home
3. Sending alerts to a customer when they are close to certain locations they may be interested in visiting

## How does this example work?
This example illustrates the first use case described above. Our data input for this example is a stream of vehicle locations via Kafka (6 vehicles). 

We are interested in knowing when a particular vehicle (vehicle 5) is inside a certain zone of interest in downtown Washington DC. For illustration purposes, we will stream the alerts to a webhook but you can alternatively set these up to be registered via kafka or any other custom application like Slack (via webhooks).

## Try it yourself
**Install Kinetica**: If you don't have Kinetica installed and running, please follow the instructions [here](https://github.com/kineticadb/examples#install-kinetica) to get everything setup to run this guide.

**Import the workbook**: Follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to import the workbook in this repo and try this example out on your own.

**More information**: You can find more information on Kinetica's geospatial capabilities from our [documentation website](https://docs.kinetica.com/7.1/location_intelligence/). We also have a [playlist on youtube](https://www.youtube.com/playlist?list=PLtLChx8K0ZZWxcmK4tD058UWWh0HJX2hQ) that provides an overview of Kinetica's geospatial capabilities.

**For Help**: If you have any questions, you can reach us on [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg) and we will get back to you immediately.
