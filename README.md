# Mysql::Partition

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/mysql/partitioner`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

`
Usage: mysql-partitioner [options]
    -c, --config CONFIG_NAME
        --cmd check or migrate
        --dry-run
    -d, --debug
`


## Example

`
CREATE TABLE `partition_test` (
  `id` bigint(20) unsigned NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) Engine=InnoDB
`

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
