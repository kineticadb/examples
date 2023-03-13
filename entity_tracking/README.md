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
 <img src="https://img.shields.io/badge/tested-%3E=v7.7.3-green"></img>  <img src="https://img.shields.io/badge/time-20 mins-blue"></img>
</p>
<h1>
Tracking entities in real-time with Kinetica
</h1>

<h3 align="center">
   <img src="https://github.com/kineticadb/examples/blob/master/_imgs/gifs/tracks_speed.gif?raw=true" width="600px"></img>
</h3>
This demo uses Tracks - a native geospatial object in Kinetica - along with other geospatial functions and visualizations to detect the following events.

* When an object enters a certain area (geo-fence)

<h3 align="center">
   <img src="https://github.com/kineticadb/examples/blob/master/_imgs/gifs/geofence.gif?raw=true" width="600px"></img>
</h3>

* When an object is dwelling or loitering

<h3 align="center">
   <img src="https://github.com/kineticadb/examples/blob/master/_imgs/gifs/dwell_loiter.gif?raw=true" width="600px"></img>
</h3>
* When two objects come within a certain distance of each other
<h3 align="center">
   <img src="https://github.com/kineticadb/examples/blob/master/_imgs/gifs/proximate.gif?raw=true" width="600px"></img>
</h3>
Kinetica’s vectorized engine makes it possible to perform these complex computations in real time as the data streams in. Even on a personal computer.

### About the data

This demo usese vessel traffic data, or Automatic Identification System (AIS) data, collected by the U.S. Coast Guard through an onboard navigation safety device that transmits and monitors the location and characteristics of vessels in U.S. and international waters in real time.

We have setup a synthetic Kafka topic that uses a sample of 4 million records from the AIS data so that it can run on personal computers

The Kafka topic is set to simulate real time information on ship locations as they stream in.

### Why is this useful?
The advancements in sensors and IoT devices now means that almost anything that moves can be recorded in real time. In fact, location enriched data or 'Tracks' data in other words is the fastest growing segment of data in the world today. 

This new data opens up a remarkable number of opportunities in varied sectors like public health, fleet optimization, proximity marketing etc.

But track data is the most valuable in real time. Most use cases require you to study and respond to track behavior as they unfold. Existing tools however, are not setup to harness the potential of Tracks in real time. 

This example is a demonstration of how Kinetica can be used to address these gaps.

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
