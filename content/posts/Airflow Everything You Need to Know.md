+++
author = "Fares Ismail"
date = "2020-07-04T12:20:00+02:00"
tags = [
    "airflow",
    "python",
    "sensor",
    "operator",
    "hook"
]
draft = "false"
title = "Everything You Probably Need to Know About Airflow"
+++

Taking a small break from scala to look into Airflow.

Also, I'm making a habit of writing those things during flights and trains :man_shrugging:... Probably the only thing keeping me from starting a travel blog.

## Table of Content

+ [Intro to Airflow](#intro-to-airflow)
+ [Task Dependencies](#task-dependencies)
+ [The Dag File](#the-dag-file)
+ [Intervals](#intervals-in-airflow)
+ [BackFilling](#backfilling)
+ [Best Practice For Airflow Tasks](#best-practice-for-airflow-tasks)
+ [Templating](#Templating)
+ [Passing Arguments to Python Operator](#passing-arguments-to-python-operator)
+ [Triggering WorkFlows](#triggering-workflows)
+ [Triggering Rules](#triggering-rules)
+ [XCOM](#xcom)
+ [Sensors](#sensors)
+ [Random TILs](#random-til)
+ [If You Must Remember 3 Things](#if-you-must-remember-3-things)

---

## Intro to Airflow

Airflow is a platform to programmatically author, schedule and monitor workflows. It does so through DAGs (directed acyclic graph) consisting of one or multiple Tasks.

A task consists of an Operator that executes a command for a job.

It is worth noting that some competitors to Airflow are: Oozie (but it is specific to hadoop job ie: spark, hive...) and [MetaFlow](https://metaflow.org/) but MetaFlow is more data science oriented.

So how does it work?

Airflow has a central process called the scheduler. Its job is to push tasks to be executed by different workers. The scheduler will read dag files from the dag folder and will access the database. Users on the other hand will only interact with the `Webserver` a graphical user interface that will represent a global view of all dags available along with their execution details both current and past. To do this, the Webserver accesses both the dag file and the database.

Additionally, Airflow can scale out on multiple machines. But for the time being, only the `Celery` and `Kubernetes` workers support Airflow in cluster mode. (More on that later).

We've mentioned Dags representing the bunch of tasks we'd like executed.

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

We also have the possibility to define a ``schedule_interval``. This way, airflow will automatically trigger the dag at regular intervals. So how does this work?

using the start_date and the interval value, airflow splits the dag into interval.

At the **end** of each interval, airflow will trigger the dag. Let us go through an example:

![Airflow Interval Example](/images/airflow/example-interval1.jpg)

In this example, our intervals are one hour long, and at the end of each interval  the dag will be triggered.

### Schedule_Intervals

We've just mentioned the ``schedule_interval`` that allows us to schedule a dag run at specific time periods.

This parameter accepts different types of input:

+ A Preset: `@once`, `@hourly`, `@daily`, `@weekly` (while simple to read and understand, it is quite limited).
+ A Cron: `0****`, `00***`, `0011*` where each asterisk from left to right mean: every minute of every hour of every day of every month and every day of the week

```text
 * * * * *  command to execute
 ┬ ┬ ┬ ┬ ┬
 │ │ │ │ │
 │ │ │ │ │
 │ │ │ │ └───── day of week (0 - 7) (0 to 6 are Sunday to Saturday, or use names; 7 is Sunday, the same as 0)
 │ │ │ └────────── month (1 - 12)
 │ │ └─────────────── day of month (1 - 31)
 │ └──────────────────── hour (0 - 23)
 └───────────────────────── min (0 - 59)
```

+ datetime.timedelta: `timedelta(minutes = 10)` or `timedelta(hours = 2)`

We can also reference time dynamically, we have access to variables like `execution_date`, `next_execution_date`, `previous...`.

## BackFilling

If the startdate of a dag is in the past, then airflow will start by re-running all previous runs of this dag. To disable this, set the parameter `catchup` to False.

## Best Practice For Airflow Tasks

As a rule of thumb and as a best practice, Airflow tasks should be Atomic and Idempotent.

### Atomic

Either a task succeeds fully and produces an end result, or it fails and does so with no side effect to the system.

The reasoning behind this is that Airflow can re-launch failed tasks multiple times and if the first failed launch does not leave the system intact, it could end up producing erroneous data in the output of the second run, or simply polluting the system.

### Idempotent

Since Airflow tasks can be re-run or retried, it becomes important to generate the same output for the same input.

## Templating

One feature of airflow is that it supports jinja templating.

And every operator in Airflow keeps a list of attributes that can be templated through the variable: ``templated_fields``.

For example:

```python

BashOperator(
    task_id = "say_hello",
    bash_command = "echo Hello {{name}}",
    dag = dag
)

```

The above example will output: ``Hello Fares`` assuming name is fares. This is because the BashOperator declares the bash_command as a templated_field. If it weren't, the output would have been: ``Hello {{name}}``

### How to Implement that in Custom Operators and Sensors

As mentioned above, to implement this in a custom operator, we would need to declare the attribute in the list of templated_fields. Airflow will take care of the rest.

## Passing Arguments to Python Operator

A PythonOperator takes a function callable and executes it within the DAG. Pretty simple... But what happens if we'd like to pass an argument to that function? There are two ways to do so, either through the args variable or the kwargs.

### Using op_args

Assume we had a function

```python
def _print_hello(name):
   print(f"Hello {name}!")
```

In the PythonOperator we can provide name in the following manner:

```python
print_context = PythonOperator(
    task_id="print_hello",
    python_callable=_print_hello,
    op_args=["Fares"]
    dag=dag,
)
```

This would be the same as calling `_print_hello("Fares")`.

### Using op_kwargs

Another way of passing arguments is through the kwargs:

```python
print_context = PythonOperator(
    task_id="print_hello",
    python_callable=_print_hello,
    op_kwargs={"name":"Fares"}
    dag=dag,
)
```

Which would be equivalent to calling `_print_hello(name="Fares")`

### Passing the Airflow Context to the Function

To pass the context to the python function simply set the `provide_context` to True in the Operator.

```python
def _print_context(**context):
   print(context)

print_context = PythonOperator(
    task_id="print_context",
    python_callable=_print_context,
    provide_context=True,
    dag=dag,
)
```

## Triggering WorkFlows

We've seen that Dags can be triggered on a specific time or timedelta using the scheduled parameter. But there are other ways to trigger dags.

One of the is using the experimental REST api for airflow (In airflow 2.0 the API no longer becomes experimental).

Here is an example:

```bash

curl -X POST \
  http://localhost:8080/api/experimental/dags/<DAG_ID>/dag_runs \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{"conf":"{\"key\":\"value\"}"}'

```

For more options and the full API see [Documentation](https://airflow.apache.org/docs/stable/rest-api-ref.html)

Another way to trigger a workflow is through sensors.

Sensors will continuously poll a system or a certain state until a condition is met, or a timeout is reached.

Airflow provides a bunch of sensors out of the box as well as the possibility to create custom sensors by extending `BaseSensor` or any other sensor. Example of existing sensors: `WebHDFSSensor`, `TimeSensor`, `TimeDeltaSensor`... [Full List Here](https://airflow.apache.org/docs/stable/_api/airflow/sensors/index.html)

We will discuss sensors in a later section.

## Triggering Rules

By default, when a dag is triggered, the only way a task can be executed is by having all its upstream tasks in success. But this behavior can be altered depending on the version of airflow and using the parameter: `trigger_rule`

In airflow 1.10.1:

+ `all_success`: (Default Value) all parents are in success
+ `all_failed`: All parents are in a failed or upstream_failed state
+ `all_done`: All parents are done executing. This can be skipped, failed, success etc...
+ `one_failed`: The task will execute as soon as one parent is in a failed state. It will not wait for all parents to finish executing.
+ `one_success`: The task will execute as soon as one parent is in a success state. It will not wait for other parents to finish execution.
+ `dummy`: Dependencies are not really existent, it will trigger at will

In Airflow 1.10.10:

We still have all the trigger rules defined in the earlier version, but to those we add:

+ `none_failed`: Will trigger a task when all the parents have finished executing AND none of them are in a failed state. Parents can however be in a skipped state.
+ `none_failed_or_skipped`: Will trigger a task when all parents have finished execution AND none of them are in a failed or skipped state. This is similar to the `one_success` but the difference is that it waits for all its parents to finish execution.

## XCOM

XCOM stands for `cross communication`. It is the way different tasks in Airflow communicate with one another. It works by defining a key and value, and pushing those into the Airflow Database. Other tasks can later on pull the value from the Database by using the key. One requirement for a value to be pushed into xcom is that it needs to be "picklable" (not sure if picklable is a real word but airflow should be able to `pickle` the value).

For additional information, pickling is the process by which python converts data into a byte stream (by serializing it) and unpickling is the deserializing process. Those are also sometimes referred to as: `serialization`, `marshalling` or `flattening`.

[Here is a list of things that can be pickled and unpickled](https://docs.python.org/2.4/lib/node66.html)

Data sent in XCOM are stored in the `Apache Airflow Backend Database`.

There are two way to push data into xcom: either by pushing it explicitly through xcom_push or implicitly by simply returning a value.

### Pushing to XCOM explicitly

Here is an example on how an Operator or a PythonOperator's callable function can push a value into xcom:

```python

context['task_instance'].xcom_push(context['task'].task_id, some_value_to_push)

```

Alright, so what is happening here? first we are retrieving the `task_instance` object from the context and then calling the xcom_push function, passing the key and the value to it. In this case we chose the key to be the task_id so we are also retrieving that value from the context.

Under the hood, we'd be calling the following function:

```python
XCom.set(
            key=key,
            value=value,
            task_id=self.task_id,
            dag_id=self.dag_id,
            execution_date=execution_date or self.execution_date)
```

[Source Code](https://github.com/apache/airflow/blob/v1-10-stable/airflow/models/taskinstance.py#L1483)

### Pushing to XCOM by returning a value

Operators can push a value in their `execute` function, and a PythonOperator can push a value to xcom by returning it in its `python_callable` function.

Example:

```python

def push_function(**context):
    return 'xyz'

```

the value "xyz" will be pushed to xcom with the key being the task_id of the function pushing this value.

### Pulling data from XCOM

Data can be pulled from xcom and additionally, we can filter based on key, task_ids, dag_id etc...

Pulling data from xcom is done through the `xcom_pull()` function. One important thing to note is that this function takes in a key argument and by default, this key argument is set to `XCOM_RETURN_KEY`. This limits the search to values that were pushed using the `return` key word and ignores those pushed manually.

To change this, pass `None` to the `key` param.

Here is an example on how to retrieve data from xcom:

```python
task_instance = context['task_instance'] ## We can also use ti instead of task_instance. They're aliases.
task_instance.xcom_pull(key = None, task_ids = "the_task_id_used_while_pushing_the_data")

```

We can also pass None to `task_ids` to retrieve all values pushed to xcom.

The full signature of the task instance pull is:

```python
def xcom_pull(
            self,
            task_ids=None,
            dag_id=None,
            key=XCOM_RETURN_KEY,
            include_prior_dates=False)
```

If we pass a value to `dag_id`, xcom will only pull values from this dag.

`include_prior_dates=False` will only pull data from current `execution_date`. Otherwise it will also include all history.

[Link to Source Code](https://github.com/apache/airflow/blob/v1-10-stable/airflow/models/taskinstance.py#L1515)

## Sensors

As we've mentioned above, sensors are special type of operators that will continuously poll a certain system/state... until a success criteria is met or a timeout is reached.

Sensors extend the `BaseSensorOperator` and define a `poke` function. That is all we need to create a custom sensor: an `init` for the class and a `poke` function.

```python
class MyCustomSensor(BaseSensorOperator):

    def __init__(self):
        ...
    def poke(self, context):
        ...
```

Poke is expected to return a boolean that indicates if a success criteria is met or not. If it is met, the sensor will set the tasks' state to `Success` and will end the execution. If the return of the poke is `False`, the sensor will continue polling based on one of two modes defined later on.

From the `BaseSensorOperator` we inherit a couple behaviors:

+ ``poke_interval``: Amount of time to wait in between two checks
+ ``timeout``: time before the Sensors stops checking the condition and sets the state to failed. By default it is set to one week: ``60*60*24*7``
+ ``soft_fail``: In the case where the timeout is reached and this is set to True, instead of failing, the sensors will simply be set to ``Skipped``
+ ``mode``: set to either `poke` or `rescheduled` Those two will be explained in the next section.

It is worth noting that `BaseSensorOperator` also extends from `BaseOperator` so in addition to the above attributes, we also have those defined in `BaseOperator`.

### Poke Mode

To understand the advantages/disadvantages of the poke vs rescheduled mode one needs to understand how Airflow schedules and launches jobs...

Airflow's configuration file will contain a couple variables that dictate the amounts of tasks that can be run at the same time both in total and within the same dag. In some cases by the same executor (If we're in Celery or Kubernetese)

At the heart of Airflow is the `Scheduler` who will interact with both the dag file and the database to submit the work to workers. There are a maximum of x slots that can be running at the same time and each running task will occupy one slot. If a task is scheduled to be run while there are no slots available, that task will be queued up until a slot becomes available.

One Airflow best practice is to use pools to regulate the available slots based on type etc... But more on that later.

In poke mode, the Sensor will occupy one slot and will not release it until a success criteria is met or a timeout reached.

In that mode we can have a guarantee that the condition will continuously be checked at regular intervals, but at the same time we would be occupying a slot for the time of execution and potentially preventing other tasks from running.

### Rescheduled Mode

In rescheduled mode; once the sensor finishes its check and returns a `False`, it will rescheduled itself for a later time (depending on poke_interval) and will release the slot it uses.

After the poke_interval, the sensor will re-check for the condition.

The advantage in this case is that once the sensor finishes its check, it releases the slot and so another task can use it to run.

The disadvantage is that if multiple tasks are running at the same time, the sensor can be queued while waiting for a slot to become available.

This can be managed by having a specific pool for scheduled tasks and coordinating long running tasks at different times during the day/night.

### Sensor Deadlock

Since sensors have a default timeout period of one week, we could easily end up with a deadlock scenario.

Assume a sensor checks if a file is present on HDFS before resuming the rest of the workflow. Also assume that this sensor is in a DAG that is scheduled to run once per day.

If the file never arrives, the sensor will continue running for one week occupying one slot. But on day two another instance of the DAG will run and another sensor will then continue running for a week occupying another slot. The same thing will happen on day three and four and so on and so forth. Eventually we will have consumed seven slots that will continue running and occupying slots, preventing other tasks from being executed.

So it is important to pay special attention to timeout, even more so when using the poke mode instead of the rescheduled mode.

---

## Random til

Here is a list of random stuff I recently learned on airflow and find cool. I'm cramming them here because I'm too lazy to re-think the structure of this article to fit them where they should fit.

### SLA

SLA stands for service level agreement.

In Airflow, we have the possibility to define a max time for either dags or tasks that should not be exceeded during a run. If that time is exceeded, an email could be sent as an alert and it will be logged in a monitoring page called SLA Misses.

SLA is typed as an ``Optional[timedelta]`` so it can either be set to None if we do not want to alert on task taking too much time, or set to a timedelta representing the max time a task execution can take.

#### Configuring SLA Miss Emails

To configure the SLA email define the following in your ``airflow.cfg`` file:

```toml
[smtp]
smtp_host = smtp.gmail.com
smtp_starttls = True
smtp_ssl = False
smtp_user = YOUR_EMAIL_ADDRESS
smtp_password = 16_DIGIT_APP_PASSWORD
smtp_port = 587
smtp_mail_from = YOUR_EMAIL_ADDRESS
```

and pass a specific `email` parameter to the operator.

#### DAG Level SLA

SLA can be set on a DAG level by passing it in the default_args:

```python
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'sla': timedelta(hours=2) ## HERE
}
```

Then at the end of each task Airflow tests whether or not the tasks' execution time exceeded the SLA. If it did, an email is sent to the set of emails defined in `default_args` and the next task continues its execution.

If the task did not exceed the SLA, the next task is executed normally and no email is sent.

So to recap: the check is made AFTER the task is executed and a violation of SLA has no impact on the execution of the DAG.

#### Task Level SLA

We have the possibility to define an SLA for a single task by passing the `sla` param. This parameter is inherited from BaseOperator so all operators/sensors should have it.

It checks for a miss at the start of the task and at the end. If a violation occurs during the tasks' execution, an email is only sent after it finishes its execution.

**NOTE** The SLA specified at the task level is the time from the DAGs execution NOT that of the task.

#### SLA Misses

Airflow give us a view of all SLA misses across all DAGs in: Browse >> SLA Misses

This can be a useful monitoring tool asides the emails that are sent.

In that view, we can see:

+ Dag id
+ Task id
+ Execution date: The execution date of the DAG with the SLA miss
+ Email sent: If an email was sent or not.
+ Timestamp: Time when the SLA miss was detected

Note that all SLA that share the same timeout will be grouped in one email.

#### SLA Miss Callback

In addition to the email that is sent on an SLA Miss and the monitoring view, Airflow allows developers to execute a callable when an SLA Miss is detected. This can be done by passing a function to the: ``sla_miss_callback`` parameter.

#### Important Note

SLA works with scheduled DAG runs only.

### Deferred Dag Assignment

Sometimes we would like to dynamically create a DAG based on some conditions or state. In that case, deferred dag assignment can be very useful:

```python
if(some_check()):
    task_1.dag = dag
    start_task >> task_1

else:
    task_2.dag=dag
    start_task >> task_2
```

That way, based on the function `some_check` our dag is constructed and if evaluates to True, task_2 will not be in that dag.

This can be quite helpful when we generate tasks dynamically.

### Priority Weights

We have previously talked about how airflow functions and mentioned that the scheduler decides which tasks to push to executors.

But how does it do that?

Each task will have a weight associated to it. The weight can go from one to int max value. The higher the weight, the more priority it has.

This weight can be set using the `priority_weight` parameter.

### Weight Rules

Weight rules are different methods used to calculate the effective weight of a given task. By default this parameter is set to Downstream but other rules exist:

+ ``Absolute``: In absolute mode, the weight of a task is the weight assigned in `priority_weight`. Seems straightforward and simple. This rule has the benefit of speeding up the dag creation since no extra computation is required to figure out the effective weight of each task. Additionally, it allows developers to have a better understanding of the execution priority and order.

+ ``Downstream``: In Downstream mode, the weight of a task is the sum of weights of this task and all its downstream tasks.

    When in Downstream mode, the upstream tasks will have higher priority and those will go down as soon as more tasks finish executing.

+ ``Upstream``: In Upstream mode the weight of a task is the sum of weights of all its upstream tasks. It is the opposite of the downstream rule. This is useful when we have multiple dag run instances and want the current dag run to finish executing before the other instances start.

### Add Docs to Tasks

Though in most cases the DAGs should be self explanatory, we sometimes might want to provide a context or an explanation to a specific task.

In those cases Airflow allows us to document tasks and dags with comments in different formats.

```python

another  = BashOperator(task_id="one", bash_command="echo another", dag=dag)

another.doc_md ="""
# Hello World

## Context

This is where context can go

## Usefulness

Here is where I can explain why this task is useful

### Note

Over here I can give more details

"""

```

In the task instance details of this task, we will be able to see the following:

![Example Of a Documented Task](/images/airflow/DocumentedTask.png)

If we do not want to write in markdown, we still have the possibility to write a regular string, in rst format, yaml and json. The last two are especially useful for printing out configuration.

This is done through the following attributes:

`doc`, `doc_md`, `doc_rst`, `doc_json`, and `doc_yaml`.

### Add Docs to Dags

In addition to adding documentation to tasks, we can also add documentations to DAGs themselves:

```python

dag= DAG(dag_id="fares-test", default_args=DEFAULT_ARGS, user_defined_macros=USER_DEFINED_MACROS, schedule_interval=None)


dag.doc_md = """
# fares-test DAG

## Actions

1. Reads Files from HDFS
2. Computes something
3. Writes files to HDFS

## Trigger Time

This DAG is scheduled everyday at 3 am.
"""

```

![Documented DAG](/images/airflow/Documented-DAG.png)

### Airflow Variables

Airflow Variables are used to store and fetch data at runtime without having to hard code it into a DAG file.

Variables are comprised of a Key and a Value and are stored in the metadata database in a table called Variables. They are also accessible to the user through the webserver in Admin >> Variables.

To create them, either do so from the Webserver by accessing Webserver >> Variables >> Create

or through the command line:

```bash

airflow variables -s my_key my_value

```

We can also pass a json configuration file through the `-e` instead of `-s`

Or through code:

```python
from airflow.models import Variable
my_var = Variable.set("my_key", "my_value")
```

But remember not to put the variables sets/gets outside of tasks or they will be executed multiple times. See Best Practices section for more information.

#### Where does Airflow Look for Variables

Airflow will look for the variable in the following places and in this order:

1. Airflow Backend Secrets
2. AIRFLOW_ENV
3. Meta store

If it finds it in one of the first two places, it will not create the expensive connection to the meta store.

#### How to Hide Variable Values

To hide the value of some sensitive information that we wish to store in Airflow Variables we need to add one of the following keywords to the key:

+ `password`
+ `secret`
+ `passwd`
+ `authorization`
+ `api_key`
+ `apikey`
+ `access_token`

The result would look like this:

![Secret Variable](/images/airflow/secret_variable.png)

Note however that anyone who has access to the DAGs or the CLI can still see the underlying value. So we shouldn't rely on this method to store sensitive values.

#### Storing Sensitive Variables in Environment Variables

This functionality is available as of Airflow 1.10.10. To make use of it, simply follow this naming convention: ``AIRFLOW_VAR_<KEY_OF_THE_VAR>``

### Best Practices

Asides the idempotent and deterministic characteristics we previously talked about here are a bunch of additional best practices:

#### Avoid doing any computation in your DAG definition

Airflow needs to execute your Python DAG file to derive the corresponding DAG. Moreover, to pick up any changes you may have made to your DAG, Airflow has to re-read your DAG file at regular intervals and sync any changes to its internal state.

If your DAG definition contains a computation, this computation will be executed every time the Dag Bag is refreshed. Which I believe is by default once every 30 seconds (configured through `process_poll_interval` in `airflow.cfg`).

Not knowing this lead me to write over 100 test messages in my kafka topic 🤷‍♂🤦‍♂

#### Using Pools

Airflow Pools are used to limit the parallelism is specific type of operators. Example: Limit database accesses to 5 tasks at any given time.

Pools can be created in the webserver through Menu >> Admin >> Pools by giving a pool name and assigning a number of slots to the pool. Then in the Task definition, we can pass the pool name in the `pool` parameter.

By doing this, we'd be allocating those slots to tasks that are part of this pool only. They will not be accessed by other tasks no matter their priority weight.

### Different Types of Executors

In the intro, we've talked about the Celery and Kubernetes executors as the only ones being able to scale out, but we haven't delved into the details of each executor and the pros and cons.

We've mentioned that the scheduler interacts with the dag files on regular bases to decide which tasks to push to the executor next.

There are different types of executors: `LocalExecutor`, `CeleryExecutor`, `KubernetesExecutor`, `SequentialExecutor`.

#### LocalExecutor

Pretty simple, everything runs on the same machine, including the scheduler. So no need for additional resources outside that machine.

Even though it runs on one machine it still supports parallelism, but it is a single point of failure and is not scalable.

Its useful for testing, but as soon as you find yourself with multiple DAGs in production needing a lot of resources, consider moving to `CeleryExecutor`

#### CeleryExecutor

Celery is built for horizontal scaling.

The Scheduler adds a message to a queue and the `CeleryBroker` delivers it to the executor or executors. If a worker goes down, the executor will re-assign this task to another worker increasing the fault tolerance.

#### KubernetesExecutor

from [Astronomer IO](https://www.astronomer.io/guides/airflow-executors-explained/) "the Kubernetes Executor relies on a fixed single Pod that dynamically delegates work and resources. For each and every task that needs to run, the Executor talks to the Kubernetes API to dynamically launch an additional Pod, each with its own Scheduler and Webserver, which it terminates when that task is completed. The fixed single Pod has a Webserver and Scheduler just the same, but it'll act as the middle-man with connection to Redis and all other workers."

#### SequentialExecutor

A much more primitive executor, it runs a single tasks instance and does not have any parallelism. It is also a single point of failure.

## If you Must Remember 3 Things

1. Airflow is a platform to programmatically author, schedule and monitor workflows
2. Do not execute computation in the Dag file outside of tasks
3. I do not have a travel blog (yet).
