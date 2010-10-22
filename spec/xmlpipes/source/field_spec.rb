require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe XMLPipes::Source::Field do

  describe '#to_hash' do

    before(:each) do
      XMLPipes::Configuration.instance.controller.stub!(:sphinx_version).and_return('0.9.9')
    end

    before(:each) do
      @field = XMLPipes::Source::Field.new(:contents, :attr => :wordcount)
      @to_hash = @field.to_hash
    end

    it 'returns an instance of Hash' do
      @to_hash.should be_an_instance_of(Hash)
    end

    it 'includes only valid keys' do
      @to_hash.keys.size.should == 1
      @to_hash[:name].should == :contents
    end

    after(:each) do
      XMLPipes::Configuration.instance.reset
    end

  end

end