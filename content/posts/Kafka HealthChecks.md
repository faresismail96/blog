+++
author = "Fares Ismail"
date = "2020-03-19T10:00:00+00:00"
tags = [
    "kafka",
    "healthcheck",
]
title = "Kafka HealthChecks"
+++

Ive been recently asked to write healthchecks for long running services that depend on kafka.

This article will not go into the need for healthchecks nor a "let it crash" design. Instead I'll delve into the struggle I had to actually write those healthchecks and more specifically checking the status of our kafka brokers.

Its important to note that I do not have an in-depth knowledge of the inner workings of kafka, and this might have probably contributed to the difficulty I found implementing said healthchecks.

Before we begin, here are some key points to keep in mind:

## What are brokers

Message brokers make the process of exchanging messages simple and reliable.

A Kafka Message Broker is the central point where messages are published to.

A kafka broker receives messages from producers and stores them on disk by unique offsets. It then allows consumers to consume the messages.

## The role of Zookeeper in all of this

Kafka uses zookeeper to store shared information about brokers, consumers ect...

For brokers, kafka determines the state of a particular broker as it sends regular heartbeat requests.

Zookeeper is also used by kafka for broker election. In the case where the leader on a specific partition fails, it will no longer be registered with zookeeper. Zookeeper will then alert the remaining brokers on that partition and will proceed with a new election.

For consumers, zookeeper keeps check of the offsets and maintains a consumer registry. They are ephemeral zNodes similar to brokers. When a consumer goes down, the node is destroyed.

## Checking the "Health" of Zookeeper

Checking the health of Zookeeper is simple:

A zookeeper client has a function ``zk.getState.isConnected``. This will return a boolean if zk is ``CONNECTED or CONNECTEDREADONLY``.

## Checking the "Health" of brokers

The first implementation of a healthcheck consisted of checking zookeeper for brokerIds (since brokers register with zookeeper). And making sure that all the brokers are indeed registered with zookeeper.

The idea came from the scaladoc in ``KafkaHealthcheck``. Which mentions:

``` scala

/**
 * This class registers the broker in zookeeper to allow
 * other brokers and consumers to detect failures. It uses an ephemeral znode with the path:
 *   /brokers/ids/[0...N] --> advertisedHost:advertisedPort
 * Right now our definition of health is fairly naive. If we register in zk we are healthy, otherwise
 * we are dead.
 */

```

Note that I was using kafka 2.11 and that after checking more recent versions, this class disappears.

### The problem with this implementation

The problem here is that my previous implementation eliminates all the benefits of the fault tolerance of kafka.

Each topic in kafka can have one or more partition. And each partition can be replicated 1 or more times.

Each partition in Kafka will have a broker as it's leader. Meaning that this broker will handle receiving messages and dispatching this information to its followers. This broker (up until version 2.4.0) is also responsible to serving the consumers. <https://cwiki.apache.org/confluence/display/KAFKA/KIP-392%3A+Allow+consumers+to+fetch+from+closest+replica>

At the same time, this broker will also maintain a list of ISR (In-Sync-Replicas). This is a list of other brokers that are in sync with the leader (In the case the topic has a replication factor). So if a leader fails, any broker from that list is a prime candidate to replacing that broker.

In other words, even if we lose a broker for a topic that is replicated, our application should not crash since we have other brokers that can step in.

### The proposed solution

The proposed solution is to: Retrieve the list of brokers from Zookeeper.
For each topic, retrieve the list of partitions, and for each partition, retrieve the list of ISR. If there is at least one broker in that list of ISR, the the partition is healthy. If all partitions for a topic are healthy and if all topics for a given application are healthy, then the application is healthy.

### Additional Resources

Here is a series of articles I found that are useful to learning more about the functioning of Kafka and Event Streaming in general.

Part one: Storage Mechanics

- <https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-1-storage-mechanics/>
- <https://thehoard.blog/how-kafkas-storage-internals-work-3a29b02e026>
Part two: Data Replication
- <https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-2-data-replication/>
Part Three: Scaling message delivery
- <https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-3-scaling-message-delivery/>
    Slightly outdated, does not mention the possibility of reading from replicas: <https://cwiki.apache.org/confluence/display/KAFKA/KIP-392%3A+Allow+consumers+to+fetch+from+closest+replica>
Part Four: Competing Goals and Lessons Learned (Plus NATS que Kafka)
- <https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-4-trade-offs-and-lessons-learned/>
Part 5: Sketching a New System
- <https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-5-sketching-a-new-system/>

Understanding Consensus: <https://bravenewgeek.com/understanding-consensus/>
