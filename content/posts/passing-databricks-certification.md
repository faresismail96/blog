+++
author = "Fares Ismail"
date = "2019-08-21T20:00:00+00:00"
title = "Passing the DataBricks Apache Spark Certification"
tags = ["Spark", "Databricks", "Spark Certification"]
+++

The following is a compilation of all the resources I've used to pass the Databricks 2.X Spark Certification, as well as some questions that came up.

## Background on the Exam

The exam databricks spark 2.x spark with scala certification is made up of 40 MCQ questions, 3 hours to answer them in total.
The registration grants you 2 trials, meaning if you fail the first attempt, you have to wait 15 days and then you can apply for a second trial.
The focus of the exam is spark DataFrames. The question distribution is outlined very well in the LinkedIn article in REX.

## Books

- Spark in Action
- Learning Spark: Outdated but has useful information regarding RDDs.
- Spark: The Definitive guide (Either Spark in Action or this).

## Rex

- LinkedIn article with GitHub repository associated: <https://www.linkedin.com/pulse/5-tips-cracking-databricks-apache-spark-certification-vivek-bombatkar/> and <https://github.com/vivek-bombatkar/Databricks-Apache-Spark-2X-Certified-Developer> Note that in the github repo there is a sample exam. 2 of the provided answers are not correct.
- Medium article <https://link.medium.com/l5Sw4zn5WY>

## Sample Exam

The following was sent to me by someone from databricks' learning center:
<https://databricks-prod-cloudfront.cloud.databricks.com/public/793177bc53e528530b06c78a4fa0e086/0/6221173/100020/latest.html>
The sample exam shows the format of the questions.

## Some Questions

1. `coalesce` vs `repartition`

2. Which line will trigger the physical plan?

3. Action vs Transformation

4. Default storage level for rdds vs DataFrames (using cache) MEMORY_ONLY and MEMORY_AND_DISK respectively.

5. Of all the blocks of code, which one has the least bottleneck. (know what `ReduceByKeyLocal` does.)

6. Does using an accumulator prevent us from using the catalyst optimizations?

7. What are the consequences of increasing the number of partitions?

8. For structured streaming review fault tolerance for every sink. no questions on spark streaming. one windowing question but it was very simple (need to know that the sliding should be smaller than the window time).

9. Apply BFS with GraphFrames.

10. CrossJoin and know that is does a cartesian product so can be memory exhaustive.

11. Broadcast is done automatically as long as the DataSet to be broadcasted is less than 10MB

12. What can we do if we want to handle a file format that is not supported by the DataFrame API

13. UDF questions. and how to call them. (parameters of `register` method, how to call the registered udf and the function that will be invoked).

14. FooBarBaz question. (printing something based on multiples of 3 or 5 or both. 4 or 5 code blocks and we need to guess the one with the correct output.)
