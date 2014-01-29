require 'sys/proctable'
require 'childprocess'

module Guard
  class GoRunner
    MAX_WAIT_COUNT = 10

    attr_reader :options, :pid

    def initialize(options)
      @options = options

      raise "Server file not found. Check your :server option in your Guarfile." unless File.exists? @options[:server]
    end

    def start
      run_go_command!
    end

    def stop
      ps_go_pid.each do |pid|
        system %{kill -KILL #{pid}}
      end
      while ps_go_pid.count > 0
        sleep sleep_time
      end
      @proc.stop
    end

    def ps_go_pid
      Sys::ProcTable.ps.select{ |pe| pe.ppid == @pid }.map { |pe| pe.pid }
    end

    def restart
      stop
      start
    end

    def sleep_time
      options[:timeout].to_f / MAX_WAIT_COUNT.to_f
    end

    private
    def run_go_command!
      if @options[:test]
        @proc = ChildProcess.build("go", "test")
      elsif @options[:ginkgo]
        @proc = ChildProcess.build("ginkgo")
      else
        @proc = ChildProcess.build("go", "run", @options[:server], @options[:args_to_s])
      end

      @proc.io.inherit!
      @proc.cwd = Dir.pwd
      @proc.start
      @pid = @proc.pid
    end
  end
end
