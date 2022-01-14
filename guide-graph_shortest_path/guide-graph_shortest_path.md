# Shortest path with Kinetica
This guide shows how to create a graph representation of Seattle's road network and then uses the shortest path solver to find routes that take the least amount of time between differnt points on the network. The guide shows how to do this for - single source to single destination, a single source to many destinations and many sources to many destinations.

## Getting started
Use the [install guide](add) to install Kinetica. Once you have access to workbench, load the accociated workbook from the github repo for this guide into Kinetica.

## Get the data

### Create the data source
We will be using seattle road network data for this guide. The data for this guide is stored in a publicly accessible AWS S3 bucket. Our first task is to create a data source that points to this bucket.


## Creating graphs in Kinetica
Graphs in Kinetica can have 4 components - nodes, edges, weights and restrictions. The primary task when creating a graph is to use the data at hand to accurately identify the required components for creating the graph.

The two videos below give a quick introduction to creating graphs in Kinetica
        - https://youtu.be/ouZb00xEzh8
        - https://youtu.be/oLYIPBRteEM

You can also read more about these concepts [here](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD)
