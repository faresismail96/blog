+++
author = "Fares Ismail"
date = "2019-08-10T09:00:00+00:00"
title = "Dynamic Scaling and Backpressure"
+++

Taking a little break from Scala to review some interesting features of spark streaming.

This article has been updated to reflect recently gained knowledge with spark streaming both in theory and practice.

An important note: This article is about backpressure and dynamic allocation in spark streaming and not normal batch jobs.

## Dynamic Allocation in Spark Streaming

Dynamic Allocation also called Elastic Scaling is a feature that lets spark dynamically adjust the number of executors to match the workload.

Spark streaming can dynamically scale up or down the number of executors based on a few configurations.

 1. `spark.streaming.dynamicAllocation.enabled`

        This enables dynamic allocation with spark streaming. needs to be true.

 2. `spark.dynamicAllocation.initialExecutors`

        Initial number of executors to start with.

 3. `spark.streaming.dynamicAllocation.scalingUpRatio` and `spark.streaming.dynamicAllocation.scalingDownRatio`

        The two configs specify when we would scale up or down the
        number of executors based on processing time and interval time.
        
        Default values are set to 0.9 and 0.3

## Back Pressure

Back Pressure is spark streamings ability to adjust the ingestion rate dynamically so that when a system is receiving data at a higher rate than it can process, we wouldnt have tasks queue up and slow down the stream.

The ingestion rate is adjusted dynamically based on previous microbatch processing time.

What about the initial ingestion rate? well this depends on the version of spark you are running.

- Prior to **Spark 2.4**: there was a bug that caused `spark.streaming.kafka.maxRatePerPartition` to be used as the initial rate AND the maximum rate per partition.
  
- As of **Spark 2.4**: We can use `spark.streaming.backpressure.initialRate` for the initial rate of ingestion. as maximum rate per partition can be set using: `spark.streaming.kafka.maxRatePerPartition`

If the input events is too high and spark streaming cannot process it in time, after the first batch is completed, spark will notice that the batch processing time is longer than the interval time and that is when backpressure will kick in to reduce the input rate.

A one sentence summary of backpressure (and an interesting article):

    Backpressure shifts the trouble of buffering input records to the
    sender so it keeps records until they could be processed
    by a streaming application.

---

## What about the practical side of things

This is where things might get a bit more complicated or hazy.

The following is a summary of what I learned recently from various sources online and the spark source code. Surprisingly the spark streaming documentation can be rather thin on the subject of dynamic allocation and backpressure.

## Spark Streaming Backpressure

- `spark.streaming.backpressure.enabled`:

        Enables backpressure in spark streaming

- `spark.streaming.kafka.maxRatePerPartition`:

        This is the maximum rate per partition to read kafka records.

- `spark.streaming.kafka.minRatePerPartition`:

        Similar to max rate per partition but this sets the min...

- `spark.streaming.backpressure.initialRate`:

        The initial rate to start with. this only works 
        on spark versions 2.4 and above. 
        Otherwise, spark streaming will use the 
        kafka max rate per partition as the initial rate.

## Spark Streaming Dynamic Allocation

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
/** Request the specified number of
executors over the currently active one */
private def requestExecutors(numNewExecutors: Int): Unit = {
       require(numNewExecutors >= 1)
       val allExecIds = client.getExecutorIds()
       logDebug(s"Executors (${allExecIds.size}) = ${allExecIds}")
       val targetTotalExecutors =
       math.max(
       math.min(maxNumExecutors, allExecIds.size + numNewExecutors),
       minNumExecutors)
       client.requestTotalExecutors(targetTotalExecutors, 0, Map.empty)
       logInfo(s"Requested total $targetTotalExecutors executors")
}
```

``` scala
val MAX_EXECUTORS_KEY =
 "spark.streaming.dynamicAllocation.maxExecutors"

// AND

private val maxNumExecutors =
conf.getInt(MAX_EXECUTORS_KEY, Integer.MAX_VALUE)
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

        If the previous micro-batch completes within the interval,
        then the engine will wait until the interval is over before
        kicking off the next micro-batch.


        If the previous micro-batch takes longer than the interval
        to complete (i.e. if an interval boundary is missed), then the
        next micro-batch will start as soon as the previous one completes
        (i.e., it will not wait for the next interval boundary).


        If no new data is available, then no micro-batch will be kicked off.

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

## Some additional resources

- Spark Source Code (more specifically: `ExecutorAllocationManager.scala`):

    <https://github.com/apache/spark/blob/branch-2.4/streaming/src/main/scala/org/apache/spark/streaming/scheduler/ExecutorAllocationManager.scala>

- Building Robust Scalable and Adaptive Applications on Spark Streaming talk during Spark Summit 2016

     <https://databricks.com/session/building-robust-scalable-and-adaptive-applications-on-spark-streaming>

- Dynamic Allocation JIRA Design Document

     <https://issues.apache.org/jira/secure/attachment/12775710/dynamic-allocation-streaming-design.pdf>
