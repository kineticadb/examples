<h3 align="center" style="margin:0px">
    <img width="200" src="../_assets/images/logo_purple.png" alt="Kinetica Logo"/>
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
 <img src="https://img.shields.io/badge/tested-%3E=v7.9-green"></img>  <img src="https://img.shields.io/badge/time-20 mins-blue"></img>
</p>
<h1>
Real time time series analysis with Kinetica
</h1>
<h3 align="center" style="margin:0px">
    <img width="600" src="assets/time_series_analysis.png" alt="Time series Logo"/>
</h3>

This workbook demonstrates a wide range of time series capabilities with Kinetica.
1. Real time data feeds: Load and analyze data from real time feeds
2. Date time functions: Manipulate data time objects and explore time buckets.
3. Window functions: Use window functions to calculate common time series indicators like moving average, cumulative sums and ranks.
4. ASOF Joins: Perform interval based inexact joins that combine two data feeds with differing time stamp values. 
5. Alerting: Trigger/stream downstream alerts based on continuosly maintained materialized views in Kinetica

## Write once, do forever
All of the analsis in the workbook is done on real time data feeds that are continuously updated. Once set up, Kinetica will keep all the queries updated automatically.

## About the data
We have set up two synthetic Kafka topics for this demonstration.

1. Trades topic: The trades topic records intraday trades data on a per-minute basis. This data includes the open, close, low and high price, and the traded volumes every minute for three stocks — Apple, Amazon and Google.
2. Quotes topic: The quotes data is produced at the rate of five to six messages per second. This records the bid price, bid size, ask price and ask size for the three stocks.

The topics are set up to mimic market feeds but the information in the topics don’t reflect actual prices right now. Another point to note is that actual market feeds are operational only during market hours (9 a.m. to 5 p.m. or extended hours), however, the topics that I have set up produce data continuously so that the code works regardless of the time zone you are in.
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
