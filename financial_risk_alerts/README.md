<h1 align = "center">
Real time financial risk alerting system
<br>
<img src="https://img.shields.io/badge/tested -%3E=v7.1.1-green"></img>  <img src="https://img.shields.io/badge/time-25 mins-blue"></img>
</h1>
<h3 align="left">

</h3>
<h6 align="center">Demo Video 👇🏼</h6>
<h3 align="center">

[![Financial risk alerting with Kinetica](https://img.youtube.com/vi/YQ7lpxwjlPY/0.jpg)](https://www.youtube.com/watch?v=YQ7lpxwjlPY)

</h3>

This demo uses Kinetica to combine a real time stream of stock prices via a Kafka topic with information on porfolio holdings information from Amazon S3 to create alerts whenenver over portfolio values drop below a certain threshold.


## Background
Many of the world's storied investors are Hedge Funds. Unlike mutual funds, to which most people have access to, hedge funds cater to institutions and wealthy investors. Fortunately, four times a year, we get a peek into this secretive world by way of regulatory filings. Hedge funds holdings give us a unique view into their thinking c/o the bets they are making.

While holdings are published only quarterly, we have real-time information on the value of their known holdings -- so we can walk-forward the value of their holdings. This has traditionally been an academic curiosity, but with recent hedge fund blow-ups, this is now a practical exercise as well.
Finally, we see stark differences in viewpoints -- a number of very successful investors are bullish while others are highly bearish. We see the heated debates on Twitter -- but the below analysis shows how their actual holdings are playing out.

## Get started
You will need an instance of Kinetica to get started. 

If you are using workbench then you can simply upload the workbook json file (fin_risk.json) to get started.

If you are on a version of Kinetica that does not include the workbench then you can use the SQL code (fin_risk.sql) along with the query functionality on [GAdmin](https://docs.kinetica.com/7.1/admin/gadmin/) to implement this demo.

Both the workbook and the SQL code include all the additional instructions you will need to try out this example.