<h2 align="center">
    <img width="300" src="https://2wz2rk1b7g6s3mm3mk3dj0lh-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kinetica_logo.svg" alt="Kinetica Logo"/>
</h2>


<h3 align="center">
    <a href="https://www.kinetica.com/">Website</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/">Docs</a>
    <span> | </span>
    <a href="https://docs.kinetica.com/7.1/api/">API Docs</a>
    <span> | </span>
    <a href="https://join.slack.com/t/kinetica-community/shared_invite/zt-12vqzfkqo-fPi760XCuL0Ub1fxCzRIWQ">Community Slack</a>
</h3>

----------------------------------------

This project contains fully reproducible examples of using Kinetica. Kinetica is a really fast, scalable cloud database for real-time analysis on large and streaming datasets. The developer edition of Kinetica is free and there are free tiers available on Azure and AWS as well.

There are three types of content here -
1. Guides: Explore specific features of Kinetica using demo data.
2. Demos: Show how to use Kinetica to solve real world challenges. These typically contain several different features of Kinetica.
3. Labs: Learn concepts through labs

Use the [catalog](https://github.com/kineticadb/kinetica-workbooks#-catalog) below to view a short description of each example and to access them.

# Getting started
## Install the free developer edition

### ❶ Download
For Mac/Linux

```shell
curl https://files.kinetica.com/install/kinetica.sh -o kinetica && chmod u+x kinetica && ./kinetica start
```

For Windows

```shell
curl https://files.kinetica.com/install/kinetica.bat -o kinetica.bat && .\kinetica.bat start
```

### ❷ Manage
The kinetica shell script manages your installation, starts, and stops the database.

Start Kinetica:
```shell
./kinetica start
```
Stop Kinetica:
```shell
./kinetica stop
```
For more commands and configuration options:
```shell
./kinetica --help
```
### ❸ Open admin portal
Administer Kinetica Developer Edition through the Kinetica Management interface. This should be available at localhost:8080/gadmin

## Provision Kinetica on the cloud
There are free versions of Kinetica that can be provisioned on Azure and/or AWS. You will have to pay a small fee for cloud infrastructure (to the cloud provider). Follow the instructions [here to provision Kinetica](https://docs.kinetica.com/7.1/azure/provision/installation/)

## Load and analyze data
Broadly speaking, there are two ways to use Kinetica -

1. Interactive workbooks - Workbooks are interactive SQL notebooks with really cool data visualization and mapping capabilities. Loading a workbook into Kinetica is really easy - simply go to the example folder that you would like to try out, download the workbook JSON file, then click the plus "+" icon in the [Workbook Explorer](https://docs.kinetica.com/7.1/azure/admin/workbench/ui/explorer/workbooks/) in Kinetica and select Import Workbook JSON.
2. Using our [APIs](https://docs.kinetica.com/7.1/api/)

# Support
If you found a bug please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

To get community support, you can: 
1. Ask a question in our [community slack channel](https://join.slack.com/t/kinetica-community/shared_invite/zt-12vqzfkqo-fPi760XCuL0Ub1fxCzRIWQ) 
2. Post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag.


# 📖 Catalog

## Guides
Explore specific features of Kinetica using demo data.
#### [Quick Start Workbook](https://github.com/kineticadb/kinetica-workbooks/tree/master/guide-quickstart)
Start your journey with a guided tour of Kinetica's analytics and visualization. Create data sources, ingest data from Amazon S3 and Kafka, then perform location analytics and visualize results on a map. Follow-along with Kinetica's [Quick Start Workbook](https://docs.kinetica.com/7.1/azure/guides/quick-start-workbook/) guide on available on Kinetica's documentation site.

#### [Shortest Path](https://github.com/kineticadb/kinetica-workbooks/tree/master/guide-graph_shortest_path)
This guide shows how to create a graph and then use the shortest path solver to find routes that take the least amount of time to traverse between - a single source to single destination, a single source to many destinations and many sources to many destinations.


## Demos
Solve real world challenges with real world data.
#### [Windmill Optimization](https://github.com/kineticadb/kinetica-workbooks/tree/master/demo-windmill_optmization)
Use Kinetica's UDF capability to predict the power output of windmills in North America. Create data sources, ingest data from Azure Blob and Kafka, create and run a Python-based linear regression UDF, then visualize the power output on a map.

## Labs
Coming soon

## More Information

See the [Documentation](http://docs.kinetica.com/7.1/azure) for more information about workbooks and the Kinetica workbench.
