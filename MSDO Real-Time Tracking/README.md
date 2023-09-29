<h3 align="center" style="margin:0px">
    <img width="200" src="../_assets/images/logo_purple.png" alt="Kinetica Logo"/>
</h3>
<h5 align="center" style="margin:0px">
    <a href="https://www.kinetica.com/">Website</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/">Docs</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/api/">API Docs</a>
    <span> | </span>
    <a href="https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg">Community Slack</a>   
</h5>
<p align = "center">
 <img src="https://img.shields.io/badge/tested-%3E=v7.1.7-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</p>

<h1>
Multiple Supply Demand Chain Optimization (MSDO) Real-Time Tracking
</h1>

This workbook demonstrates the application of Kinetica's Multiple Supply Demand Chain Optimization (MSDO) solver with using a Kafka server to create <b>real-time tracking</b> scenario.
In this project phase, we will commence the tracking of GPS signals emitted by a fleet, subsequently conducting comprehensive data analysis based on the information received from the trucks.

## Background

Matching supply chain logistics to demand-based routing is a daily and non-trivial task, crucial for numerous companies like Amazon and Uber. The overarching goal is to optimize routing within specific industry constraints. Kinetica's MSDO solver offers a versatile solution applicable across various industries. Optimization objectives can range from distributing power by transformers to consumers with varying needs, transporting tons of gasoline to different stations, or delivering packets of goods from depots to multiple locations. What remains consistent in all these transport challenges is that both supply and demand quantities are not constant.

In this project phase, we initiate the tracking of GPS signals emitted by a fleet, followed by comprehensive data analysis based on the information received from the trucks. The project has been developed to emulate signals originating from a fleet of ten trucks, all adhering to routes defined by the optimal route solver's output. The signals are produced via the Kafka server and stream data into the workbook. The workbook introduces random delays to each truck's data when presenting real-time information about truck locations.

## Try it yourself
All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica), if you don't have an instance of Kinetica available.

You can learn more about Kinetica's graph API from our [documentation](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).

## Support
For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

## Contact Us
* Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
* Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
* Email us: [support@kinetica.com](mailto:support@kinetica.com)
* Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
