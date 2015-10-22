require 'mysql/partitioner/partition'
module Mysql
  module Partitioner
    module Operation
      class Range < Abstract

        def check!
          type = get_partition_type()
          if type != "RANGE" and type != nil
            raise "Partition type mismatch #{type}"
          end
        end
        
        def get_current_bounded_partitions
          get_current_partitions.select {| item| item.bounded? }
        end

        def get_current_partitions
          results = self.session.query(<<SQL)
SELECT PARTITION_EXPRESSION, PARTITION_DESCRIPTION, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, SUBPARTITION_EXPRESSION
FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_NAME="#{ self.table }" AND TABLE_SCHEMA="#{ self.database }"
SQL
          results.map {|item|
            Mysql::Partitioner::Partition::Range.new(item["PARTITION_DESCRIPTION"])
          }
        end

        def add_partitions(partitions)
          return if partitions.empty?
          partition_defs = partitions.select.map {|item|
            item.to_partition_def
          }.join(",\n  ")
          self.session.alter("ALTER TABLE #{self.table} REORGANIZE PARTITION pmax INTO ( #{partition_defs }, PARTITION pmax VALUES LESS THAN MAXVALUE )" )
        end

        def create_partitions(key, partitions)
          
          partition_defs = partitions.select.map {|item|
            item.to_partition_def
          }.join(",\n  ")
          self.session.alter(<<SQL)
ALTER TABLE #{self.table} PARTITION BY RANGE (#{key}) (
  #{partition_defs},
  PARTITION pmax VALUES LESS THAN MAXVALUE)
SQL
        
        end

        def drop_partitions(partitions)
          return if partitions.empty?
          names = partitions.map{|item| item.name }.join(",")
          self.session.alter("ALTER TABLE #{self.table} DROP PARTITION #{names}" )
        end

        def migrate_partitions(old_partitions, new_partitions) 
          self.drop_partitions(old_partitions - new_partitions)
          self.add_partitions(new_partitions - old_partitions)
        end
      end
    end
  end
end
