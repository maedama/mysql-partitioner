require 'spec_helper'

describe Mysql::Partitioner do
  it 'has a version number' do
    expect(Mysql::Partitioner::VERSION).not_to be nil
  end
end
