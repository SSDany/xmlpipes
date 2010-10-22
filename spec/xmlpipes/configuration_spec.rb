require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Configuration do

  before(:all) do
    @instance = XMLPipes::Configuration.instance
    @root = @instance.root
  end

  it 'defaults address to 127.0.0.1' do
    @instance.address.should == '127.0.0.1'
    @instance.searchd.address.should == '127.0.0.1'
  end

  it 'defaults port to 9312' do
    @instance.port.should == 9312
    @instance.client.port.should == 9312
    @instance.searchd.port.should == 9312
  end

  it 'defaults environment to "development"' do
    @instance.environment.should == 'development'
  end

  it 'does not allow "*" by default' do
    @instance.should_not be_allow_star
  end

  describe 'block configuration' do

    it 'allows to specify a new root' do
      XMLPipes::Configuration.configure { |c| c.root = '/somewhere/far/far/away' }
      @instance.root.should == '/somewhere/far/far/away'
    end

    it 'allows to specify a new environment' do
      XMLPipes::Configuration.configure { |c| c.environment = 'benchmarking' }
      @instance.environment.should == 'benchmarking'
    end

    it 'resets paths' do
      XMLPipes::Configuration.configure { |c| 
        c.root = '/somewhere/far/far/away'
        c.environment = 'benchmarking'
      }

      searchd = @instance.searchd

      @instance.searchd_file_path.should  == '/somewhere/far/far/away/sphinx/benchmarking'
      @instance.pipes_path                == '/somewhere/far/far/away/tmp/pipes'
      searchd.pid_file.should             == '/somewhere/far/far/away/tmp/searchd.benchmarking.pid'
      searchd.log.should                  == '/somewhere/far/far/away/log/searchd.log'
      searchd.query_log                   == '/somewhere/far/far/away/log/searchd.query.log'
    end

  end

  describe '#apply_config' do

    def apply_config(data)
      FakeFS do
        File.open('test.yml', File::WRONLY|File::TRUNC|File::CREAT) { |c| c << {:test => data}.to_yaml }
        XMLPipes::Configuration.configure { |c| c.environment = :test }
        @instance.apply_config('test.yml')
      end
    end

    it 'allows to specify a custom searchd_file_path' do
      apply_config('searchd_file_path' => '/path/to/indexes')
      @instance.searchd_file_path.should == '/path/to/indexes'
    end

    it 'allows to specify a custom bin_path' do
      apply_config('bin_path' => '/bin/path')
      @instance.controller.bin_path.should == '/bin/path'
      @instance.bin_path.should == '/bin/path'
    end

    it 'allows to specify a custom searchd_binary_name' do
      apply_config('searchd_binary_name' => 'searchd_binary_name')
      @instance.controller.searchd_binary_name.should == 'searchd_binary_name'
      @instance.searchd_binary_name.should == 'searchd_binary_name'
    end

    it 'allows to specify a custom indexer_binary_name' do
      apply_config('indexer_binary_name' => 'indexer_binary_name')
      @instance.controller.indexer_binary_name.should == 'indexer_binary_name'
      @instance.indexer_binary_name.should == 'indexer_binary_name'
    end

    it 'allows to specify a custom config_file' do
      apply_config('config_file' => '/path/to/sphinx.conf')
      @instance.controller.path.should == '/path/to/sphinx.conf'
      @instance.config_file.should == '/path/to/sphinx.conf'
    end

    it 'allows to specify searchd settings' do
      apply_config('searchd' => {'client_timeout' => 60})
      @instance.searchd.client_timeout.should == 60
    end

    it 'allows to specify indexer settings' do
      apply_config('indexer' => {'mem_limit' => '128M'})
      @instance.indexer.mem_limit.should == '128M'
    end

    it 'allows to specify defaults (index_options)' do
      apply_config('html_strip' => 1)
      @instance.index_options[:html_strip].should == 1
    end

    it 'allows to specify a custom address' do
      apply_config('address' => '10.0.0.2')
      @instance.address.should == '10.0.0.2'
      @instance.searchd.address.should == '10.0.0.2'
    end

    it 'allows to specify a custom address using the "searchd" section' do
      apply_config('searchd' => {'address' => '10.0.0.2'})
      @instance.address.should == '10.0.0.2'
      @instance.searchd.address.should == '10.0.0.2'
    end

    it 'allows to specify a custom port' do
      apply_config('port' => 9313)
      @instance.port.should == 9313
      @instance.searchd.port.should == 9313
    end

    it 'allows to specify a custom port using the "searchd" section' do
      apply_config('searchd' => {'port' => 9313})
      @instance.port.should == 9313
      @instance.searchd.port.should == 9313
    end

    it 'allows to specify the "enable_star" flag' do
      apply_config('enable_star' => true)
      @instance.should be_allow_star
      @instance.index_options[:enable_star].should == true
    end

    describe 'and if the "enable_star" flag is set to true' do

      before(:each) do
        apply_config('enable_star' => true, 'min_prefix_len' => 5)
        @instance.index_options[:enable_star].should == true
      end

      it 'resets min_prefix_len to 1' do
        @instance.index_options[:min_prefix_len].should == 1
      end

    end

  end

  describe '#client' do

    it 'returns an instance of the Riddle::Client' do
      @instance.client.should be_an_instance_of Riddle::Client
    end

    it 'uses proper address'
    it 'uses proper port'

  end

  describe '#render' do

    before(:each) do
      @config = @instance.render
    end

    it 'includes all necessary indexes into the sphinx config' do
      @config.should =~ /index titles_core/
      @config.should =~ /index books_core/
      @config.should =~ /index books_delta : books_core/
    end

    it 'includes all necessary sources into the sphinx config' do
      @config.should =~ /source titles_core_source/
      @config.should =~ /source books_delta_source : books_core_source/
      @config.should =~ /source books_core_source/
      @config.should =~ /source manga_core_source/
      @config.should =~ /source manga_delta_source : manga_core_source/
    end

    it 'includes any explicit prefixed or infixed fields' do
      @config.should =~ /prefix_fields\s+= title, authors, publisher/
      @config.should =~ /infix_fields\s+= title, authors, publisher/
    end

    it 'does not include prefix fields in indexes where nothing is set' do
      @config.should_not match(/index titles_core\s+\{\s+[^\}]*prefix_fields\s+=[^\}]*\}/m)
    end

  end

  describe '#build' do
    it 'generates configuration and writes it into the sphinx.conf file' do
      FakeFS.activate!
      XMLPipes::Configuration.configure { |c| c.environment = :test }
      @instance.should_receive(:render).and_return('configuration')
      @instance.build
      File.read(File.join(@instance.root, 'config/test.sphinx.conf')).should == 'configuration'
      FakeFS.deactivate!
    end
  end

  after(:each) do
    @instance.root = @root
    @instance.reset
  end

end