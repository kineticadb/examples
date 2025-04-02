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
 <img src="https://img.shields.io/badge/tested-%3E=v7.2.2.13-green"></img>  <img src="https://img.shields.io/badge/time-5mins-blue"></img>
</p>
<h1>
Supercharge knowledge graph analytics by embedding vector similarity
</h1>

# 📘 Enriching Graphs with Vector Similarity in Kinetica

This workbook demonstrates how to combine vector similarity with graph semantics to create a richer, more intelligent knowledge graph—one that can answer complex questions with simple queries. It replicates the use case detailed in our blog post where movie preference vectors are used to add meaningful, similarity-based edges to a demographic graph.

# 🧠 What This Demonstrates

Traditional graphs are great for modeling relationships, but the connections don’t always capture semantic meaning. Similarly, vector embeddings can capture affinities, but they often flatten structure and miss long-range dependencies. This example shows how to inject vector similarities directly into a graph to combine the strengths of both approaches.

Key concepts demonstrated:

- Using movie-genre vectors to compute similarity between individuals
- Creating new graph edges based on vector thresholds
- Executing multi-hop queries that combine demographic and similarity-based paths
- Leveraging Kinetica’s hybrid OLAP + Graph + Vector SQL engine


# Try it yourself
All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica) instructions, if you don't have an instance of Kinetica available.

# Support
For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

# Contact Us
* Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
* Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
* Email us: [support@kinetica.com](mailto:support@kinetica.com)
* Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
