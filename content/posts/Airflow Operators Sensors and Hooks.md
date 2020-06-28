+++
author = "Fares Ismail"
date = "2020-05-21T10:00:00+02:00"
tags = [
    "airflow",
    "python",
    "sensor",
    "operator",
    "hook"
]
draft = "true"
title = "Airflow: Operators, Sensors and Hooks"
+++

Taking a small break from scala to look into Airflow.

Also, I'm making a habit of writing those things during flights and trains :man_shrugging:... Probably the only thing keeping me from starting a travel blog.

## Table of Content

1. [Intro to Airflow](#intro-to-airflow)
2. [Task Dependencies](#task-dependencies)
3. [The Dag File](#the-dag-file)
4. [Intervals](#intervals-in-airflow)
5. [Templating](#Templating)
6. [Passing Arguments to Python Functions](#passing-arguments-to-python-functions)

---

## Intro to Airflow

Airflow is a platform to programmatically author, schedule and monitor workflows. It does so through DAGs (directed acyclic graph) consisting of one or multiple Tasks.

A task consists of an Operator that executes a command for a job.

A DAG might look something like this:

![Example Dag](/images/airflow/example-dag1.png)

Every task is an operator, and airflow comes with a bunch of prebuilt Operators such as:

+ BashOperator: An operator to run a bash command.
+ PythonOperator: An operator that will execute a python function

The tasks in the dag define clear dependencies. In the previous example, task1 will be executed and its success will trigger the execution of task2. Its failure will halt the execution of all tasks that depend on task1 and in our case, this represents all the other tasks.

## Task Dependencies

The Dag file is written in python. and there are two ways to define dependencies between dags:

assume we've already created the tasks ``task1``, ``task2``, ``task3a``, ``task3b`` (more on that in a bit), we can then declare the dependencies in the following way:

```python
task1 >> task2 >> [task3a, task3b]
```

This is in my opinion the clearest way to showcase that task2 depends on task 1 and that both task 3a and 3b depends on task2. Notice that we can group tasks in between brackets.

Another way to define dependencies between tasks in to explicitly use the keywords ``set_upstream`` or ``set_downstream``. To better understand it, I found it helpful to think of the ensemble of tasks as a stream and have data flow in that stream.

```python
    task1.set_downstream(task2)
    task2.set_downstream([task3a, task3b])
```

or the other way around:

```python
    task3a.set_upstream(task2)
    task3b.set_upstream(task2)
    task2.set_upstream(task1)
```

You'd be correct in questioning the usefulness of the ``set_upstream``. In this case it is much more verbose (since one task is branching out to many), but if the case was reversed and multiple tasks were converging into one, then it'd have been easier to use ``set_upstream``

## The Dag File

As mentioned earlier, tasks and dependencies are defined using python in a Dag file. The following example is fairly self explanatory but I'll still comment on some points:

```python
with DAG(
    dag_id='my_dag',
    schedule_interval='@daily',
    start_date=dt.datetime(2019, 2, 28)
) as dag:
    task1 = DummyOperator('task1')
    task2 = DummyOperator('task2')
    task3a = DummyOperator('task3a')
    task3b = DummyOperator('task3b')

    task1 >> task2 >> [task3a, task3b]
```

This type of dag definition uses the context manager, so that all the tasks defined here will belong to the same dag. Another possible declaration though more verbose:

```python
dag = DAG(
    dag_id='branch_without_trigger',
    schedule_interval='@once',
    start_date=dt.datetime(2019, 2, 28)
)

    task1 = DummyOperator('task1', dag= dag)
    task2 = DummyOperator('task2', dag= dag)
    task3a = DummyOperator('task3a', dag= dag)
    task3b = DummyOperator('task3b', dag= dag)
```

you can see why in most cases option one is preferred.

## Intervals in Airflow

In the previous section, we've seen that in the definition of the dag, we provide a start_date.

We also have the possibility to define a ``schedule_interval``. This way, airflow will automatically launch trigger the dag at regular intervals. So how does this work?

using the start_date and the interval value, airflow splits the dag into interval.

At the end of each interval, airflow will trigger the dag. Let us go through an example:

![Airflow Interval Example](/images/airflow/example-interval1.jpg)

In this example, our intervals are one hour long, and at the end of each interval  the dag will be triggered.

### Schedule_Intervals

## Templating

One feature of airflow is that it supports jinja templating.

### What does this mean

### How can this help me

### How to Implement that in Custom Operators and Sensors
