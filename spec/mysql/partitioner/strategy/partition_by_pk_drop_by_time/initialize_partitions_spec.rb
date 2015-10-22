require 'spec_helper'
describe Mysql::Partitioner::Strategy::PartitionByPkDropByTime do

  let(:partition) { Mysql::Partitioner::Partition::Range }
  let(:klass) { Mysql::Partitioner::Strategy::PartitionByPkDropByTime }
  let(:base_config) {
    { 
      :key      =>  "id",
      :time_key => "created_at",
      :ttl      =>  86400,
      :range    =>  100,
      :min_empty_partitions       => 3,
      :desirable_empty_partitions => 5,
    }
  }


  
  describe "initialize_partitions" do

    let(:strategy) {
      klass.new(
        operation, base_config
      )
    }

    subject(:operation) {
      operation = Mysql::Partitioner::Operation::Range.new(nil, nil)
      allow(operation).to receive(:check!).and_return(true)
      allow(operation).to receive(:partitionated?).and_return(true)
      allow(operation).to receive(:create_partitions).and_return(true)
      spy(operation)
      operation
    }

    it "Should create partitions" do
      strategy.initialize_partitions

      expect(operation).to have_received(:create_partitions).with(
        "id",
        [ 
          partition.new(100),
          partition.new(200),
          partition.new(300),
          partition.new(400),
          partition.new(500),
        ]
      )
    end 
  end
end
