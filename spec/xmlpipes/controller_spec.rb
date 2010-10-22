require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Controller do

  before(:each) do
    @controller = XMLPipes::Controller.allocate
    @controller.instance_variable_set(:@path, '/path/to/sphinx.conf')
    @controller.stub!(:indexer).and_return('indexer')
    @controller.stub!(:running?).and_return(false)
    @backquotes = '`'.to_sym
  end

  describe '#merge' do

    it 'builds a "merge" command' do
      @controller.should_receive(@backquotes).with(%r{--merge core delta})
      @controller.merge('core', 'delta')
    end

    it 'uses proper config' do
      @controller.should_receive(@backquotes).with(%r{--config "/path/to/sphinx.conf"})
      @controller.merge('core', 'delta')
    end

    it 'uses the "rotate" flag when running' do
      @controller.stub!(:running?).and_return(true)
      @controller.should_receive(@backquotes).with(%r{--rotate})
      @controller.merge('core', 'delta')
    end

    it 'does not use the "rotate" flag otherwise' do
      @controller.should_receive(@backquotes) { |c| c.should_not =~ %r{--rotate} }
      @controller.merge('core', 'delta')
    end

    it 'allows to specify the "merge-dst-range" switch (as a Range)' do
      @controller.should_receive(@backquotes).with(%r{--merge-dst-range hits 10 100})
      @controller.merge('core', 'delta', :ranges => {:hits => 10..100})
    end

    it 'allows to specify the "merge-dst-range" switch (as an Array)' do
      @controller.should_receive(@backquotes).with(%r{--merge-dst-range hits 10 100})
      @controller.merge('core', 'delta', :ranges => {:hits => [10,100]})
    end

  end

end