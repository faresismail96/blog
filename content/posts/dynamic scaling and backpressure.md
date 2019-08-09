+++
author = "Fares Ismail"
date = "2019-08-05T19:00:00+00:00"
title = "Dynamic Scaling and Backpressure"
+++

Taking a little break from scala to review essential must know settings in spark.

This article has been updated to reflect a recently gained additional knowledge with both settings.

An Important note before we begin, this article is aimed at spark streaming dynamic allocation and back pressure. 

Dynamic Allocation
------------------

Dynamic Allocation also called Elastic Scaling is a feature that lets spark dynamically match workload.

Spark allows us to adjust the allowance for increased traffic by scaling up the number of executors up to a defined maximum. Similarly, spark allows us to scale down to a minimum.

to do so, you need to adjust the following settings:
    
    - `spark.streaming.dynamicAllocation.enabled: true`
    - `spark.streaming.dynamicAllocation.minExecutors: x` where x is 
        the # of min executors.

by default, spark scales up when the ratio between the ProcessingTime and the BatchTime is 0.9 and scales down when that ration is 0.3

those can be changed using: `spark.streaming.dynamicAllocation.scalingUpRatio` and `spark.streaming.dynamicAllocation.scalingDownRatio`

What about the number of executors we start with?
Spark also has a param for that:
`spark.dynamicAllocation.initialExecutors`.
 
 _Note_: _Make sure the initial executors are always greater than the min Executors_
 

Back Pressure
--------------

Back Pressure happens when a system is receiving data at a higher rate than it can process due to a short spike.

This can lead to a bottleneck in the downstream and slow the entire stream down.

If ProcessingTime exceeds IntervalTime for a while, it can cause resource exhaustion.


Note: `spark.streaming.kafka.maxRatePerPartition` according to the documentation is: 

````
the maximum rate (in messages per second) at which each Kafka 
partition will be read by this direct API
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
Backpressure shifts the trouble of buffering input records to the 
sender so it keeps records until they could be processed 
by a streaming application.
```

---


<h1> What about the practical side of things? </h1>

This is where things get a little bit more complicated or hazy...

The following is the result of what I could gather from my personal experience with spark streaming and the documentation and various articles I read online.

On many occasions, I had to check the source code to get a clearer answer.


One of the most important thing about Dynamic allocation and backpressure is the configuration.

Surprisingly, the official documentations lacks in depth with that regards.

So here a list of conf I could gather from here and there:

<h2> Spark Streaming Backpressure </h2>
 
 - `spark.streaming.backpressure.enabled`:
    
        Enables backpressure in spark streaming

 - `spark.streaming.backpressure.initialRate`:

        The initial rate to start with. this only works 
        on spark versions 2.4 and above. 
        Otherwise, spark streaming will use the 
        kafka max rate per partition as the initial rate.

 - `spark.streaming.kafka.maxRatePerPartition`:

        This is the maximum rate per partition to read kafka records.

 - `spark.streaming.kafka.minRatePerPartition`:

        Similar to max rate per partition but this sets the min...

<h2> Spark Streaming Dynamic Allocation </h2>

Reminder, the below settings are for spark streaming DA and not Spark Dynamic Allocation.

 - `spark.streaming.dynamicAllocation.enabled`:

        Enables DA for spark streaming

 - `spark.streaming.dynamicAllocation.scalingUpRatio`:

        Scales up when the ratio between the ProcessingTime and the 
        BatchTime is above x value.

 - `spark.streaming.dynamicAllocation.scalingDownRatio`:

        Similar as above but for scaling down.

 - `streaming.dynamicAllocation.scalingInterval`:

        Interval in seconds to apply scaling.

 - `spark.streaming.dynamicAllocation.maxExecutors`:

        The name of this conf is very misleading and it took me a 
        while to figure it out...

        The name might imply that this represents the maximum number 
        of executors we can scale up to... but it is not.
        The maximum number of executors we can reach is the `spark.cores.max` 
        divided by the `spark.executor.core` setting.
        
        This configuration, is the number of executors spark streaming 
        will request from the cluster manager (mesos, yarn...)
        which is why we can see the following in the logs:
                
                "Capping the total amount of executors to X"
                "Requested total X executors"
        
        But dont take my word for it... let us quickly check the spark 
        source code for verification:

```scala
 /** Request the specified number of executors over the currently active one */
  private def requestExecutors(numNewExecutors: Int): Unit = {
    require(numNewExecutors >= 1)
    val allExecIds = client.getExecutorIds()
    logDebug(s"Executors (${allExecIds.size}) = ${allExecIds}")
    val targetTotalExecutors =
      math.max(math.min(maxNumExecutors, allExecIds.size + numNewExecutors), minNumExecutors)
    client.requestTotalExecutors(targetTotalExecutors, 0, Map.empty)
    logInfo(s"Requested total $targetTotalExecutors executors")
  }
```

```scala
val MAX_EXECUTORS_KEY = "spark.streaming.dynamicAllocation.maxExecutors"

// AND

private val maxNumExecutors = conf.getInt(MAX_EXECUTORS_KEY, Integer.MAX_VALUE)
```
So what does this tell us?

First an foremost, maxNumExecutors is the `spark.streaming.dynamicAllocation.maxExecutors`
or by default it is the `Integer.MAX_VALUE`.

alright... but what about the algorithm?
it tells us:
the targetTotalExecutors to request is the maximum number between: the minNumExecutors and the min of (maxNumExecutors, `allAvailableExec + math.max(math.round(ratio).toInt, 1)`)

> where allAvailableExec is the size of all the executorIds.

> newNumExecutors is the max between one and the rounded ratio.

> ratio is defined as 
```scala
val ratio = averageBatchProcTime.toDouble / batchDurationMs
```



I get things might have gotten a bit confusing... but let us go back to what is important, configuring our cluster.

in order to do so, we need to know based on what will our cluster scale up or scale down.

there are two things to know:

`batch time`: this is a fixed amount in seconds. this represents the interval of time during which we will be processing data.
 from the spark structured streaming official doc:
```
If the previous micro-batch completes within the interval, 
then the engine will wait until the interval is over before 
kicking off the next micro-batch.


If the previous micro-batch takes longer than the interval 
to complete (i.e. if an interval boundary is missed), then the 
next micro-batch will start as soon as the previous one completes 
(i.e., it will not wait for the next interval boundary).


If no new data is available, then no micro-batch will be kicked off.
```

The first scenario implies idle time.

The second scenario implies queued tasks.


`processing time`: the time it takes us to process the data. this can be less, equal or greater than batch time as seen in the example above.


Let us look at some use cases:

Case    |   Processing Time| Batch Time    | Ratio
:----   |:---------------: |:--------------|:------:
1       | 2s               | 60s           | 0.033
2       | 10s              | 60s           | 0.166
3       | 20s              | 60s           | 0.333
4       | 30s              | 60s           | 0.5
5       | 45s              | 60s           | 0.75
6       | 60s              | 60s           | 1
7       | 80s              | 60s           | 1.33

Now assume our `ScalingUp` ratio is 0.9 and `ScalingDown` ratio is 0.3

what happens in each case?

 1. Case 1 and 2: **ratio <= ScalingDown** so spark will request to kill x executors. (x is calculated based on the maxExecutor or the algorithm shown above)
        
        the reason behind this is because the processing time is 
        significantly smaller than the batch time, so there is a lot 
        of idle time and so we probably have more resources than we need.
 2. Case 3, 4, 5: **ratio is neither smaller than ScalingDown nor bigger than ScalingUp**, so we do nothing.

 3. Case 6 and 7: **ratio >= ScalingUp** so spark will request additional executors based on the algorithm mentioned above.

        The reason behind this is because the processing time is 
        close to or bigger than the Batch time, so most likely 
        additional resources are needed.

