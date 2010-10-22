# source: ActiveSupport

unless ::File.respond_to?(:atomic_write)

  class ::File
    def self.atomic_write(file_name, temp_dir = Dir.tmpdir)

      require 'tempfile' unless defined?(Tempfile)
      require 'fileutils' unless defined?(FileUtils)

      temp_file = Tempfile.new(basename(file_name), temp_dir)
      yield temp_file
      temp_file.close

      begin
        old_stat = stat(file_name)
      rescue Errno::ENOENT
        check_name = join(dirname(file_name), ".permissions_check.#{Thread.current.object_id}.#{Process.pid}.#{rand(1000000)}")
        open(check_name, "w") { }
        old_stat = stat(check_name)
        unlink(check_name)
      end

      FileUtils.mv(temp_file.path, file_name)
      chown(old_stat.uid, old_stat.gid, file_name)
      chmod(old_stat.mode, file_name)

      nil
    end
  end

end