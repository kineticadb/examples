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
 <img src="https://img.shields.io/badge/tested-%3E=v7.1.8-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</p>
<h1>
A simple illustration of Geofencing with Kinetica
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

### Try it yourself
All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica), if you don't have an instance of Kinetica available.

# Support
For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

# Contact Us
* Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
* Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
* Email us: [support@kinetica.com](mailto:support@kinetica.com)
* Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
