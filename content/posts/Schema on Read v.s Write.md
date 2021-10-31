+++
author = "Fares Ismail"
date = "2021-10-31T12:20:00+02:00"
tags = [
    "Schema on Read",
    "Schema on Write",
    "Datalake"
]
draft = "false"
title = "Schema on Read v.s Schema on Write"
+++

There are two mechanisms to store data in a database.

Either follow a schema on read approach or a schema on write approach.

## Schema on Write

This is typically used with relational databases.

With this approach, the schema is defined and created before the data is inserted into a db.

It usually follows the below steps:

1. Create the schema (create tables)
2. Load the data
3. Query the data and extract insight

The advantage of this approach is that reading the data (querying) becomes much faster since the schema is already known.

But this approach also presents some inconveniences

- To be able to create accurate schema, the data needs to be known and well understood in advance.
- The data is modeled and sometimes modified to a specific use case
- If the schema is redefined, the table is dropped and reloaded. Is can be problematic with large datasets and data with foreign keys.

## Schema on Read

On the flip side, schema on read consists of delaying the schema definition to the moment we query the data.

1. Load the unstructured data
2. Apply a schema
3. Query the data with that schema

This mechanism allows us to store unstructured and structured data without worrying about the schema or any transformations. It facilitates a fast ingestion because the data does not follow any internal schema.

It is up to the code that does the ETL to handle the data. No need to drop tables and reload data at a schema change, simply change the code that does the querying.

Schema on read also allows us to store the full data as is, and therefore that same data can be reused for different applications/purposes as it has not been subjected to a specific schema yet.

On inconvenience though is that the stored data can contain a lot of missing/invalid values.

## Summary

There is no overall better approche, just a better approche for a use case.

|*Schema on Write* | *Schema on Read*             |
|:-----------------|  ---------------------------:|
|Fast reads        | Slow Reads                   |
|Slower loads      | Fast Loads                   |
|Structured data   | Structured/Unstructured data |
|Fewer Errors      | More errors                  |
|SQL               | NoSQL                        |
