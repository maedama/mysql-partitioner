module Mysql
  module Partitioner
    module Partition
      class Range
        attr_accessor :name, :less_than

        def initialize(less_than, name=nil)
          self.less_than = less_than == "MAXVALUE" ? Float::MAX : less_than.to_i
          if name == nil then
            name = self.build_name
          end
          self.name = name
        end

        def bounded?
          self.less_than < Float::MAX
        end

        def build_name()
          "p" + self.less_than.to_s
        end

        def to_partition_def
          "PARTITION #{self.name} VALUES LESS THAN (#{self.less_than})"
        end
        
        def eql?(other)
          self == other
        end
        
        def ==(other)
          other.instance_of?(self.class) && other.name == self.name
        end

        def hash
          self.name.hash
        end
      end
    end
  end
end
