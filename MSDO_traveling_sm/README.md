<h1 align = "center">
Modeling and solving the traveling salesman problem as an MSDO
<br>
<img src="https://img.shields.io/badge/tested-%3E=v7.7.1-green"></img>  <img src="https://img.shields.io/badge/time-15 mins-blue"></img>
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
If you don't have Kinetica installed and running, please follow the [Install Kinetica](https://github.com/kineticadb/examples#install-kinetica) section to get everything setup to run this guide.

The instructions are provided within the workbook itself. Follow the instructions [here](https://github.com/kineticadb/examples#how-to-run-these-examples) to try this demo out on your own.

If you are unfamiliar with Kinetica's graph API you can learn more about it [here](https://docs.kinetica.com/7.1/graph_solver/network_graph_solver) or this [course playlist](https://www.youtube.com/playlist?list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD).

If you have any questions, you can reach us on [Slack](https://join.slack.com/t/kinetica-community/shared_invite/zt-13ynqf304-bxuI_JKd9bW1BXny~Ze1QQ) and we will get back to you immediately.
