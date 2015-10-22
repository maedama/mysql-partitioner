# Mysql::Partitioner

Mysql partition management tools

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mysql-partitioner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mysql-partitioner

## Usage

```
Usage: mysql-partitioner [options]
    -c, --config CONFIG_NAME
        --cmd check or migrate
        --dry-run
    -d, --debug
```

sample config

* https://github.com/maedama/mysql-partitioner/blob/master/sample/config.yaml

## Features


### Supported partition type

Currently it supports, Range partition without sub partition

### Supported Partition Strategy

##### PartitionByPkDropByRange

This Strategy allows us to partition table with Primary Key, and at the same time manage partition by timestamp

| Parameter | Description |
|-----------|-------------|
| Key | Partition Key |
| time_key | Time key |
| min_empty_partitions | If empty partitions is less than this number, check command would fail |
| desirable_empty_partitions | When migration happens, mysql-partitioner will prepare this number of  partitions  for future |
| range | Range of each partitions |
| ttl | when migration happens tool will drop partitions with all items in partition is older than this ttl |


Typical example of partitioning with timestamp is like bellow.

```
CREATE TABLE test(
    id big int unsigned NOT NULL,
    content varchar(255) NOT NULL,
    created_at DATETIME NOT NULL,
    PRIMARY KEY(id, created_at)
) Engine=InnoDB;

``` 

By including created_at in primary key, mysql can know which partition each data belongs to.
And each data will be unique if and only if it is unique in the partition they belong to.

But this approach has major fallback in terms of performance.

i.e Query like bellow would be very slow in such a partitions

```
SELECT * FROM test WHERE id in (1, 100, 10000,1000000,10000000000000)
```

Instead of such an partitioning, this strategy partions table like bellow,

```
CREATE TABLE test(
    id big int unsigned NOT NULL,
    content varchar(255) NOT NULL,
    created_at DATETIME NOT NULL,
    PRIMARY KEY(id, created_at)
) Engine=InnoDB;

```

When migration happens, toosl find all partitions with following condition and drops them.

* Is not most recent active partition
* All items in partitions is older that specified ttl

Additionally tool will also try to make new_partitions with specified parameter


## Example

```
CREATE TABLE `partition_test` (
  `id` bigint(20) unsigned NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) Engine=InnoDB
```

Initialize first partition

```
% ./bin/mysql-partitioner -c sample/config.yaml --cmd migrate
I, [2015-10-22T12:23:55.415436 #10605]  INFO -- : Running migrate on sample1 dry_run=false
I, [2015-10-22T12:23:55.423031 #10605]  INFO -- : ALTER TABLE partition_test PARTITION BY RANGE (id) (
  PARTITION p1000000 VALUES LESS THAN (1000000),
  PARTITION p2000000 VALUES LESS THAN (2000000),
  PARTITION p3000000 VALUES LESS THAN (3000000),
  PARTITION p4000000 VALUES LESS THAN (4000000),
  PARTITION p5000000 VALUES LESS THAN (5000000),
  PARTITION pmax VALUES LESS THAN MAXVALUE)

I, [2015-10-22T12:23:55.524145 #10605]  INFO -- : success
```

Insert old data
```
# Old
mysql> INSERT INTO partition_test VALUES(100, "2015-01-01 00:00:00", NOW());
Query OK, 1 row affected (0.01 sec)

# New
mysql> INSERT INTO partition_test VALUES(2000000, NOW(), NOW());
Query OK, 1 row affected (0.00 sec)
```

Update partition
```
% ./bin/mysql-partitioner -c sample/config.yaml --cmd migrate
I, [2015-10-22T12:27:02.860359 #10752]  INFO -- : Running migrate on sample1 dry_run=false
I, [2015-10-22T12:27:02.878468 #10752]  INFO -- : ALTER TABLE partition_test DROP PARTITION p1000000
I, [2015-10-22T12:27:03.022669 #10752]  INFO -- : ALTER TABLE partition_test REORGANIZE PARTITION pmax INTO ( PARTITION p6000000 VALUES LESS THAN (6000000),
  PARTITION p7000000 VALUES LESS THAN (7000000),
  PARTITION p8000000 VALUES LESS THAN (8000000), PARTITION pmax VALUES LESS THAN MAXVALUE )
I, [2015-10-22T12:27:03.359712 #10752]  INFO -- : success
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mysql-partitioner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
