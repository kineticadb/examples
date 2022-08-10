<h3 align="center" style="margin:0px">
    <img width="200" src="https://2wz2rk1b7g6s3mm3mk3dj0lh-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kinetica_logo.svg" alt="Kinetica Logo"/>
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
 <img src="https://img.shields.io/badge/tested-%3E=v7.7.1-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
</p>
<h1>
Modeling and solving the traveling salesman problem as an MSDO
</h1>

This workbook demonstrates how to run the travelling salesmen problem in batches - using the MSDO solver. In order to cast the problem into MSDO context, we need to assume each salesmen as a supply side with one truck each and the capacity of the truck equal to the number of deliveries. Likewise, the stop locations will be assumed to be the demand site with a demand size of exactly one. Steps involved:

1. Read Graph Road Network raw data from S3 bucket
2. Create Supply and Demand tables with the note above in mind s.t., the total supplies matches total demand size exactly.
3. Run match/graph with MSDO solver.
4. Class Break Visualization of the salesmen routes on the output table by breaking on the salesmen id (SUPPLY ID).
5. Re-run match graph with animation options, i.e., svg options, by generating the tracks - option is 'output_tracks' (see below).
6. Flip the goal to a batch od shortest path runs; from supply location to every other stop (demand) location, create od matrix by the cross join of supply/demand tables and assign od id as the sum of the two
7. Run 'match_batch_solves' of /match/graph and see the result as animated svg paths.

### Try it yourself
All the steps and instructions are provided within the workbook itself. All you need to do is follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to load the workbook into Kinetica and try this out on your own. 

Please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica), if you don't have an instance of Kinetica available.

You can learn more about Kinetica's graph API from our [documentation](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).

# Support
For bugs please submit an [issue on Github](https://github.com/kineticadb/examples/issues). Please reference the example that you are having an issue with in the title.

For support your can post on [stackoverflow](https://stackoverflow.com/questions/tagged/kinetica) under the kinetica tag or [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg).

# Contact Us
* Ask a question on slack: [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-1bt9x3mvr-uMKrXlSDXfy3oU~sKi84qg)
* Follow on Github: <a class="github-button" href="https://github.com/kineticadb" data-size="large" aria-label="Follow @kineticadb on GitHub">Follow @kineticadb</a> 
* Email us: [support@kinetica.com](mailto:support@kinetica.com)
* Visit: [https://www.kinetica.com/contact/](https://www.kinetica.com/contact/)
