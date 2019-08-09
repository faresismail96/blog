+++
author = "Fares Ismail"
date = "2019-08-05T19:00:00+00:00"
title = "Dynamic Scaling and Backpressure"
+++

Taking a little break from scala to review essential must know settings in spark.

This article has been updated to reflect a recently gained additional knowledge with both settings.

Dynamic Allocation
------------------

Dynamic Allocation also called Elastic Scaling is a feature that lets spark dynamically match workload.

Spark allows us to adjust the allowance for increased traffic by scaling up the number of executors up to a defined maximum. Similarly, spark allows us to scale down to a minimum.

to do so, you need to adjust the following settings:
    
    - `spark.streaming.dynamicAllocation.enabled: true`
    - `spark.streaming.dynamicAllocation.minExecutors: x` where x is the # of min executors.

by default, spark scales up when the ratio between the ProcessingTime and the BatchTime is 0.9 and scales down when that ration is 0.3

those can be changed using: `spark.streaming.dynamicAllocation.scaleUpRatio` and `spark.streaming.dynamicAllocation.scaleDownRatio`

What about the number of executors we start with?
Spark also has a param for that:
`spark.dynamicAllocation.initialExecutors`.
 
 _Note_: _Make sure the initial executors are always greater than the min Executors_
 
---

<h3> Mapping between Kafka Partitions and Spark Workers </h3>

 The correlation between a kafka partition and a spark executor is one to n.
 that means that a single kafka partition can only be consumed by one executor and that one spark executor can consume multiple kafka partitions.

 This also means that it makes no sense to have `spark.dynamicAllocation.maxExecutors` bigger than the number of executors.


---


Back Pressure
--------------

Back Pressure happens when a system is receiving data at a higher rate than it can process due to a short spike.

This can lead to a bottleneck in the downstream and slow the entire stream down.

If ProcessingTime exceeds IntervalTime for a while, it can cause resource exhaustion.


Note: `spark.streaming.kafka.maxRatePerPartition` according to the documentation is: 

````
the maximum rate (in messages per second) at which each Kafka partition will be read by this direct API
````

This param can prevent microbatches from being overwhelmed when there is a sudden surge in messages from Kafka Producers.

But this config only works with the API.
if using receiver based kafka-spark integration, use `spark.streaming.receiver.maxRate`


Backpressure allows the ingestion rate to be dynamically and automatically set using previous microbatch processing times.

to enable backpressure, we need to set: `spark.streaming.backpressure.enabled` to true.

what about the initialRate? for the initialRate we use `spark.streaming.kafka.maxRatePerPartition`, because of a bug where spark was using this config instead of the actual initial rate.
as of April 2018 and for spark versions 2.4 and above, this was corrected. so you can use `spark.streaming.backpressure.initialRate`.

So if the input size is too high and spark streaming cannot process it in time, after the first batch is finished processing, spark will notice that the processing time is longer than the interval time and that is when backpressure will kick in, reducing the input rate.

a one line summary of backpressure taken from https://jaceklaskowski.gitbooks.io/spark-streaming/spark-streaming-backpressure.html

```
Backpressure shifts the trouble of buffering input records to the sender so it keeps records until they could be processed by a streaming application.
```

---