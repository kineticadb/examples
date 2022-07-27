# Shortest path with Kinetica
This guide shows how to use Kinetica's graph API to the shortest routes between different points in Seattle. The entire exercise is done using SQL. There are three types of routes that we solve - single source to single destination, a single source to many destinations and many sources to many destinations.


## Getting started
If you don't have Kinetica installed and running, please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kineticaa) section to get everything setup to run this guide.

The instructions are provided within the workbook itself. So the fastest way to try this out would be to download the workbook json file (guide-graph_shortest_path.json) and [import it into Kinetica](https://github.com/kineticadb/examples#how-to-run-these-examples).

If you are unfamiliar with Kinetica's graph API you can learn more about it [here](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).
