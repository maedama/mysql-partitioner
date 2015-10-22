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

  describe "Check" do
    let(:operation) {
      operation = Mysql::Partitioner::Operation::Range.new(nil, nil)
      allow(operation).to receive(:check!).and_return(true)
      allow(operation).to receive(:partitionated?).and_return(true)
      allow(operation).to receive(:get_max_val).and_return(nil)
      allow(operation).to receive(:get_current_bounded_partitions).and_return([
        partition.new(100),
        partition.new(200),
      ])
      operation
    }

    context "When partitions larger equals to desrired" do
      subject(:strategy) {
        klass.new(
          operation, base_config.merge({ :desirable_empty_partitions => 2, :min_empty_partitions => 1 })
        )
      }

      it "should return false" do
        expect(strategy.check).to be(true)
      end
    end

    context "When partitions larger smaller than desired by equals to min" do
      subject(:strategy) {
        klass.new(
          operation, base_config.merge({ :desirable_empty_partitions => 5, :min_empty_partitions => 2 })
        )
      }

      it "should return false" do
        expect(strategy.check).to be(true)
      end
    end

    context "When partitions smaller than min" do
      subject(:strategy) {
        klass.new(
          operation, base_config.merge({ :desirable_empty_partitions => 5, :min_empty_partitions => 3  })
        )
      }

      it "should return false" do
        expect(strategy.check).to be(false)
      end
    end
  end
end
