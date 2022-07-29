<h1 align = "center">
Finding optimal routes with an electric vehicle charging stop using Kinetica's graph API
<br>
<img src="https://img.shields.io/badge/tested-%3E=v7.1.6-green"></img>  <img src="https://img.shields.io/badge/time-30 mins-blue"></img>
</h1>
<h3 align="left">

</h3>
<h6 align="center">Demo Video 👇🏼</h6>
<h3 align="center">

[![Optimal routes](https://img.youtube.com/vi/sE1-F9ExFJ4/0.jpg)](https://www.youtube.com/watch?v=sE1-F9ExFJ4)
</h3>

In this demo, we use Kinetica’s graph API to create a 1.2 million node graph representation of the road network in and around Detroit. We then use this graph network to find the optimal route between a source and destination point by picking the best charging station out of 268 different options. We repeat these computations every 5 seconds using a SQL procedure with new sets of source and destination points that are streaming in from a Kafka topic.
There are three steps in this analysis. 
1. Find the shortest path from source point to all the charging stations.
2. Compute the inverse shortest path from all the charging stations to the destination. 
3. Combine the two to find the optimal path with the lowest total cost.

The entire analysis is done with SQL on a small instance of Kinetica on Azure. We have set up all the data so that the example is fully reproducible. Follow the instructions below to try this out on your own.

### Try it yourself
All you need to get started is an instance of Kinetica and the workbook file. Open the raw json workbook file in a tab and save it on to your desktop. You can then easily import them into your instance of Kinetica. 

Kinetica is available via Azure and AWS as a managed service, it can also be installed and run on your local machine as a Docker container. Follow the instructions [here](https://www.kinetica.com/try/) to install Kinetica.
If you have any questions, you can reach us on [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg) and we will get back to you immediately.
