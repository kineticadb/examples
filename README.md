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
    <a href="https://join.slack.com/t/kinetica-community/shared_invite/zt-13ynqf304-bxuI_JKd9bW1BXny~Ze1QQ">Community Slack</a>
    
</h3>
<h3 align="center">
<img src="https://2wz2rk1b7g6s3mm3mk3dj0lh-wpengine.netdna-ssl.com/wp-content/uploads/2022/02/modern_architecture_04.gif"></img>
</h3>

This project contains **fully reproducible examples** of using Kinetica. Kinetica is a really fast, scalable cloud database for real-time analysis on large and streaming datasets. The developer edition of Kinetica is free and there are free tiers available on Azure and AWS as well.

# How to run these examples
You will need an instance of Kinetica to run each example (see [below](https://github.com/kineticadb/examples#install-kinetica) for guidance on installation). Each folder in this repo contains a fully reproducible example that uses either SQL or other supported languages (Python, Java, Javascript etc.).

### SQL examples
Examples that use SQL will typically include a JSON workbook file and a SQL file. There are two ways to run these.
- Workbench: Workbench is an interactive SQL notebook environment that is custom built to showcase the unique ANSI SQL and data visualization capabilities of Kinetica. Workbench is currently only available on cloud offerings of Kinetica (see section below for more details). For examples that use SQL, download the workbook JSON file, then click the plus "+" icon in the [Workbook Explorer](https://docs.kinetica.com/7.1/azure/admin/workbench/ui/explorer/workbooks/) in Kinetica and select Import Workbook JSON.
- GAdmin: GAdmin is an administration application for Kinetica that is by default available on port 8080. It is still the only native interface for querying the database if you use the developer edition or the on premise version of Kinetica. GAdmin however, will eventually be phased out in favour of Workbench. For examples that use SQL you can use the SQL file that is available in each example to run SQL queries on GAdmin.
### Other languages
Kinetica provides [APIs](https://docs.kinetica.com/7.1/api/) across different languages (Python, JavaScript, Java etc.) that can be used to connect to and query a Kinetica database server using a third party client.

# Install Kinetica
There are several options for installing Kinetica, these are listed below.
### [Launch Kinetica as a service on the cloud](https://www.kinetica.com/platform/cloud/)
There are free versions of Kinetica that can be provisioned as a managed service on Azure or AWS (coming soon). You will have to pay a small fee for cloud infrastructure (to the cloud provider). Follow the instructions [here to provision Kinetica](https://www.kinetica.com/platform/cloud/) on the cloud.

### [Install the free developer edition](https://www.kinetica.com/try/)
Kinetica offers a free developer edition that can be installed on Windows or Mac/Linux operating systems. Dev edition of Kinetica requires Docker with at least 8GB of RAM allocated. You can follow the instructions [here](https://www.kinetica.com/try/) to download and install the developer edition.

### Install the on-premise version of Kinetica
You can also deploy an on-premise version of Kinetica. You can find more information on the different installation options [here](https://docs.kinetica.com/7.1/install/installation-options/). 

# Support
If you found a bug please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

To get community support, you can: 
1. Ask a question in our [community slack channel](https://join.slack.com/t/kinetica-community/shared_invite/zt-12vqzfkqo-fPi760XCuL0Ub1fxCzRIWQ) 
2. Post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag.


## More Information
See our [Documentation](http://docs.kinetica.com/7.1/azure) for more information about workbooks and the Kinetica workbench.
