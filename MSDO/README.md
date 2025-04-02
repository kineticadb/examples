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
 <img src="https://img.shields.io/badge/tested-%3E=v7.1.7-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</p>
<h1>
Multiple Supply Demand Chain Optimization (MSDO) Graph Solver
</h1>

This workbook demonstrates the application of Kinetica's Multiple Supply Demand Chain Optimization (MSDO) solver to optimize a scenario with two supply depots with 12 trucks that need to service multiple demand destination that are spread around Washington DC.

<h3 align="center" style="margin:0px">
<img width="600" src="../_assets/images/MSDO.png" alt="MSDO banner"/>
</h3>

## Background

Matching supply chain logistics to demand based routing is a daily, non-trivial task essential to several companies like Amazon and Uber. The common objective is to optimize routing under domain specific constraints to the needs of a particular industry. Kinetica's MSDO solver provides a generic and uniformly applicable solution to the needs of different industries. The optimization quantity could be the power transported by the transformers to multiple consumers with different power needs, or tons of gasoline transported by tankers to various stations, or simply the packets of goods delivered from multiple depots to multiple geographical locations. The main point in all of these transport problems is that neither the supply, nor the demand side transport quantity is a constant.

For instance, a depot can have  many vehicles with a variety of truck capacities to deliver varying amounts of  goods at each customer location spread across a vast geography as seen below. The ultimate goal is to find the ‘optimal’ routing and scheduling for each truck individually such that the total transportation cost is minimized.

This SQL workbook showcases how to leverage Kinetica’s Multiple Supply Demand Optimization (MSDO) Graph Solver, a powerful tool designed for complex, routing optimization. The workbook walks you through a scenario involving 18 customers and 12 trucks with variable capacities, originating from 2 supply depots in the Washington DC area. Unlike traditional solvers, the MSDO solver considers a multitude of constraints, such as package volume, truck capacity, and even time penalties, to find the optimal route for each truck. 
The workbook is divided into three main sections:
- Data setup, where we prepare the data sources, tables, and a graph representation of the Washington DC road network.
- Optimal route calculation using the MSDO solver and expalnation of options that can be used in a MSDO solver.
- Optimal route calculation using the MSDO solver's TSM(Travelling salesman mode) option.


## Try it yourself
All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica), if you don't have an instance of Kinetica available.

You can learn more about Kinetica's graph API from our [documentation](https://docs.kinetica.com/7.2/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).

## Support
For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

## Contact Us
* Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
* Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
* Email us: [support@kinetica.com](mailto:support@kinetica.com)
* Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
