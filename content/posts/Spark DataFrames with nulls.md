+++
author = "Fares Ismail"
date = "2019-01-19T10:00:00+00:00"
tags = [
    "Spark",
    "nulls",
]
title = "Spark Odd Behavior with Nulls"
+++

Once again, I will put a 5 hour flight into good use to detail an interesting/odd behavior encountered with spark while dealing with nulls.

Any basic spark tutorial will tell you that there are a couple ways to create dataframes.

Some of which are:

1. Transforming existing dataframes.

2. Reading a file.

3. Parallelizing over a collection.

The first two will not be in the scope of this article. Instead I will focus on an odd behavior encountered while creating a dataframe. More specifically, the behavior is in regards to null values and how they are treated.

Let me start with a little bit of context:

I was reading a row and a specific schema and creating a dataframe, I noticed that the resulting DataFrame would differ for the same inputs depending on the underlying ``createDataFrame`` function that is being called.

Lets start with something simple:

```scala

    val schema: StructType =
      StructType(
        List(
          StructField("Name", StringType, nullable = false),
          StructField("Age", IntegerType, nullable = false)
        )
      )

    val nestedRows: Row = Row("Fares", 23)
    import scala.collection.JavaConverters._
    val data = List(nestedRows).asJava
    val df: DataFrame = spark.createDataFrame(data, schema)

    df.show()

```

We would expect the dataframe to look like this:

``` text

+-----+---+
| Name|Age|
+-----+---+
|Fares| 23|
+-----+---+

```

Alright now assume the age was ``null``. Looking at the Schema (Age is required and cannot be null), we would expect the ``createDataFrame`` to throw a null pointer exception.

Except that when we run the below code:

```scala

    val schema: StructType =
      StructType(
        List(
          StructField("Name", StringType, nullable = false),
          StructField("Age", IntegerType, nullable = false)
        )
      )

    val nestedRows: Row = Row("Fares", null)
    import scala.collection.JavaConverters._
    val data = List(nestedRows).asJava
    val df: DataFrame = spark.createDataFrame(data, schema)

    df.show()

```

we get:

```text

+-----+---+
| Name|Age|
+-----+---+
|Fares|  0|
+-----+---+

```

The reason behind this has the do with the underlying functions being called by this specific ``createDataFrame``. In the example of TimestampType, the underlying function being called is: ``fromExternalRows``

```scala

  def fromExternalRows(output: Seq[Attribute], data: Seq[Row]): LocalRelation = {
    val schema = StructType.fromAttributes(output)
    val converter = CatalystTypeConverters.createToCatalystConverter(schema)
    LocalRelation(output, data.map(converter(_).asInstanceOf[InternalRow]))
  }

```

This will in turn call: ``CatalystTypeConverters.createToCatalystConverter(schema)``

and in the case of a timestamp type, we end up calling:

```scala

  /**
   * Returns the number of micros since epoch from java.sql.Timestamp.
   */
  def fromJavaTimestamp(t: Timestamp): SQLTimestamp = {
    if (t != null) {
      t.getTime() * 1000L + (t.getNanos().toLong / 1000) % 1000L
    } else {
      0L
    }
  }

```

So when we execute a code like the one below:

```scala

    val schema: StructType =
      StructType(
        List(
          StructField("TS", TimestampType, nullable = false)
        )
      )

    val nestedRows: Row = Row(null)
    import scala.collection.JavaConverters._
    val data = List(nestedRows).asJava
    val df: DataFrame = spark.createDataFrame(data, schema)

    df.show()

```

We end up with:

```text

+-------------------+
|                 TS|
+-------------------+
|1970-01-01 02:00:00|
+-------------------+

```

The same "Default Value" case can be encountered with ``IntegerType``, ``BooleanType``, ``LongType``, ``DoubleType`` ect...

## What if we do not want this behavior

This only happens when we call a specific instance of the ``createDataFrame`` passing it a java list. If such a behavior is to be avoided, one simply has to use another instance of the function. For example, we can call in the following manner:

```scala

    val schema: StructType =
      StructType(
        List(
          StructField("TS", TimestampType, nullable = false)
        )
      )

    val nestedRows: Row = Row(null)
    val df: DataFrame = spark.createDataFrame(spark.sparkContext.parallelize(List(nestedRows)), schema)

    df.show()

```

And end up with the expected error:

```text

  The 0th field 'TS' of input row cannot be null.

```

The reason for that is due to the instance of the function being called. in the case of the latter its:

```scala

  /**
   * Creates a `DataFrame` from an RDD[Row].
   * User can specify whether the input rows should be converted to Catalyst rows.
   */
  private[sql] def createDataFrame(
      rowRDD: RDD[Row],
      schema: StructType,
      needsConversion: Boolean) = {
    // TODO: use MutableProjection when rowRDD is another DataFrame and the applied
    // schema differs from the existing schema on any field data type.
    val catalystRows = if (needsConversion) {
      val encoder = RowEncoder(schema)
      rowRDD.map(encoder.toRow)
    } else {
      rowRDD.map{r: Row => InternalRow.fromSeq(r.toSeq)}
    }
    val logicalPlan = LogicalRDD(schema.toAttributes, catalystRows)(self)
    Dataset.ofRows(self, logicalPlan)
  }

```
