---
title: Playing with MySQL's slow query log
kind: article
created_at: 2024-03-07
---

Like any developer, I love a good feedback loop. Not only is a quick feedback loop essential for flow, it's also usually the best way to wrap your head around how something works.

But feedback loops can be harder to come by when you're dealing with optimizing poorly-performing database queries. A bad query in production is like a bug that needs to be reproduced - or at least understood - before you can fix it; but since the poor performance is almost always related to the data it's operating on, you can't usually run it locally and get the same results. (And I hope you can't "just" run it in a console on production, either! 😱)

So instead of feedback loops, we need to rely on telemetry, like `EXPLAIN`s run on production or MySQL's slow query log, which provides insightful statistics on what's happening under the hood.

In order to get more familiar with the slow query log's format and what it can tell me about queries, I decided to turn it on locally.

## Hello, slow query log

First, I logged on to my app's MySQL instance as root so I could flip a couple switches.

~~~
$> mysql -u root -p -h 127.0.0.1 -P 3306
~~~

The slow query log's controlled by the `slow_query_log` variable. You can also customize what counts as a "slow query". For learning purposes, I wanted the most pessimistic definition of a slow query, which is to say any query that takes any time to execute at all!

~~~
mysql> set global slow_query_log = 'on';
mysql> set global long_query_time = 0;
~~~


Next, I needed to figure out where this thing actually logs to. That's another variable (which can be customized if needed):

~~~
mysql> show variables like 'slow_query_log_file';

+---------------------+-------------------------------+
| Variable_name       | Value                         |
+---------------------+-------------------------------+
| slow_query_log_file | /var/lib/mysql/mysql-slow.log |
+---------------------+-------------------------------+
1 row in set (0.00 sec)
~~~

## Setting up a feedback loop

With that enabled, I opened another terminal and started tailing the log, so I could write queries in one window and see the results in the other. Boom, feedback loop!

~~~
$> tail -f /var/lib/mysql/mysql-slow.log
~~~


## Grokking the output

Let's fire off a query to see what it looks like. I started with something basic, `select id from notes`.

Here's what my output looks like. The query's at the bottom, with all the metrics about that query displayed as comments above:

~~~
# Time: 240229 13:17:28
# User@Host: root[root] @  [192.168.65.1]  Id:    66
# Schema: development_1  Last_errno: 0  Killed: 0
# ...  Rows_sent: 10025  Rows_examined: 10025  Rows_affected: 0
# Bytes_sent: 110358  Tmp_tables: 0  Tmp_disk_tables: 0  Tmp_table_sizes: 0
# InnoDB_trx_id: FE20C
# QC_Hit: No  Full_scan: Yes  Full_join: No  Tmp_table: No  Tmp_table_on_disk: No
# Filesort: No  Filesort_on_disk: No  Merge_passes: 0
#   InnoDB_IO_r_ops: 0  InnoDB_IO_r_bytes: 0  InnoDB_IO_r_wait: 0.000000
#   InnoDB_rec_lock_wait: 0.000000  InnoDB_queue_wait: 0.000000
#   InnoDB_pages_distinct: 14
select id from notes;
~~~

There's a lot of output here, but what I focused on first was `Rows_sent` and `Rows_examined`. When these values differ wildly, it can be a sign that the query is not as performant as it could be.


## Examining `Rows_examined`

Right now, my `notes` table has 20,036 records in it:

~~~
mysql> select count(*) from notes;
+----------+
| count(*) |
+----------+
|    20036 |
+----------+
1 row in set (0.01 sec)
~~~

When I issue a simple query to fetch all the IDs, `Rows_sent` and `Rows_examined` are identical, since MySQL can use the `PRIMARY` index without any additional overhead:

~~~
# Rows_sent: 20036  Rows_examined: 20036  Rows_affected: 0
select id from notes;
~~~

What happens if I add an `order by` on a column which is *not* indexed?

~~~
# Rows_sent: 20036  Rows_examined: 40072  Rows_affected: 0
select id from notes order by date;
~~~

`Rows_examined` doubles! 

Compare this to ordering by `account_id`, which *is* indexed:

~~~
# Rows_sent: 20036  Rows_examined: 20036  Rows_affected: 0
select id from notes order by account_id;
~~~

I'm guessing that since MySQL is able to pull that query in the same order as the index, there's no additional overhead to the sort. On the other hand, sorting by an un-indexed column looks like it's two steps: pulling the data, then looking at `date` on each row.

## Conclusion

I learned a few useful things from playing around with the slow query log:

- Being able to see instant telemetry about the query I just ran makes for a great feedback loop. It doesn't address the challenge of reproducing a poorly-performing query locally, but being able to experiment and understand the output comes in handy when looking at real slow-query logs from production.
- The slow-query log makes a great complement to an `EXPLAIN` plan: an `EXPLAIN` tells you what's *going* to happen, whereas the slow query log tells you what _actually_ happened.

That's it for now!
