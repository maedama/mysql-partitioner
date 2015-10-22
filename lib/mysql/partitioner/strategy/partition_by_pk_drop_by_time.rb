require 'mysql/partitioner/partition'
module Mysql
  module Partitioner
    module Strategy
      class PartitionByPkDropByTime
        def initialize(operation, config)
          @operation = operation or raise "operation not specified"
          @key = config[:key] or raise "Key not specified"
          @time_key = config[:time_key] or raise "time column not specified"
          @ttl = config[:ttl] or raise "ttl not specified"
          @range = config[:range] or raise "range not specified"
          @min_empty_partitions = config[:min_empty_partitions] or raise "min_empty_partitions not specified"
          @desirable_empty_partitions = config[:desirable_empty_partitions] or raise "desirable_empty_partitions not specified"
          @operation.check!
        end

        def check!()

          raise "Not partitioned" unless @operation.partitionated?
          current = @operation.get_current_bounded_partitions
          
          empty = find_empty_partitions(current)
          if empty.size < @min_empty_partitions then
            raise "empty partitions is less than minimum was=#{empty.size} should_be=#{@min_empty_partitions}"
          else
            true
          end
        end

        def check()
          success = true
          begin
            check!
          rescue => e
            success = false
          end
          return success
        end
      
        def migrate()
          if @operation.partitionated? then
            update_partitions()
          else
            initialize_partitions()
          end
        end

        def initialize_partitions()
          max_less_than = 0
          new = []
          @desirable_empty_partitions.times do
            max_less_than = max_less_than + @range
            new.push( Mysql::Partitioner::Partition::Range.new(max_less_than) )
          end
          @operation.create_partitions(@key, new)
        end

        def update_partitions()
          current = @operation.get_current_bounded_partitions
          raise "partition is some how empty" if current.empty?
          empty = find_empty_partitions(current)

          new = []
          if empty.size < @desirable_empty_partitions then
            max_less_than = current.last.less_than
            ( @desirable_empty_partitions - empty.size ).times do
              max_less_than = max_less_than + @range
              new.push( Mysql::Partitioner::Partition::Range.new(max_less_than) )
            end
          end
          old = find_old_partitions(current)
          @operation.migrate_partitions(current, current - old + new)
        end

          
        def find_empty_partitions(current_partitions)
          
          max_val = @operation.get_max_val(@key)
          return current_partitions if max_val.nil?
          max_val = max_val.to_i
          max_active_partition = find_partition(current_partitions, max_val)
          raise "partition not found error" if max_active_partition.nil?

          current_partitions.select{|item|
            item.less_than > max_val && item != max_active_partition
          }
        end

        def find_old_partitions(current_partitions)
        
          max_val = @operation.get_max_val(@key)
          return [] if max_val.nil?
          max_val = max_val.to_i

          max_active_partition = find_partition(current_partitions, max_val)
          raise "partition not found errorr" if max_active_partition.nil?

          old_index = current_partitions.rindex{|item|
            time = @operation.of_max_val(@key, @time_key, item.name)
            time && time.to_i + @ttl < Time.now.to_i && item != max_active_partition
          }

            
          old_index && old_index >= 0 ? current_partitions[0 .. old_index] : []
        end

        def find_partition(partitions, val)
          return partitions.find{|item| item.less_than > val} 
        end
      end
    end
  end
end
