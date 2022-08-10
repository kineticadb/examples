<h3 align="center">
    <img width="300" src="https://2wz2rk1b7g6s3mm3mk3dj0lh-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kinetica_logo.svg" alt="Kinetica Logo"/>
</h3>
<h2 align="center">The database for time and space</h2>
<h3 align="center">
    <a href="https://www.kinetica.com/">Website</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/">Docs</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/api/">API Docs</a>
    <span> | </span>
    <a href="https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg">Community Slack</a>   
</h3>

<h1 align = "center">
Multiple Supply Demand Chain Optimization (MSDO) Graph Solver
<br>
<img src="https://img.shields.io/badge/tested-%3E=v7.7.1-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</h1>
This workbook demonstrates the application of Kinetica's Multiple Supply Demand Chain Optimization (MSDO) solver to optimize a scenario with two supply depots with 12 trucks that need to service multiple demand destination that are spread around Washington DC.

## Background

Matching supply chain logistics to demand based routing is a daily, non-trivial task essential to several companies like Amazon and Uber. The common objective is to optimize routing under domain specific constraints to the needs of a particular industry. Kinetica's MSDO solver provides a generic and uniformly applicable solution to the needs of different industries. The optimization quantity could be the power transported by the transformers to multiple consumers with different power needs, or tons of gasoline transported by tankers to various stations, or simply the packets of goods delivered from multiple depots to multiple geographical locations. The main point in all of these transport problems is that neither the supply, nor the demand side transport quantity is a constant.

For instance, a depot can have  many vehicles with a variety of truck capacities to deliver varying amounts of  goods at each customer location spread across a vast geography as seen below. The ultimate goal is to find the ‘optimal’ routing and scheduling for each truck individually such that the total transportation cost is minimized.

### Try it yourself
If you don't have Kinetica installed and running, please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica) section to get everything setup to run this guide.

The instructions are provided within the workbook itself. Follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to try this demo out on your own.

If you are unfamiliar with Kinetica's graph API you can learn more about it [here](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).

If you have any questions, you can reach us on [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg) and we will get back to you immediately.

## Support
If you found a bug please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

To get community support, you can: 
1. Ask a question in our [community slack channel](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg) 
2. Post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag.

## More Information
See our [Documentation](http://docs.kinetica.com/7.1/azure) for more information about workbooks and the Kinetica workbench.
