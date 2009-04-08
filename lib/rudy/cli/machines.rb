

module Rudy::CLI
  class Machines < Rudy::CLI::Base
    
    def connect
      puts "Rudy Connect".bright

      if @argv.cmd
        @argv.cmd = [@argv.cmd].flatten.join(' ')
        if @global.user.to_s == "root"
          exit unless Annoy.are_you_sure?(:medium)
        end
      end
      
      rudy = Rudy::Machines.new(:config => @config, :global => @global)
      rudy.connect(@argv.cmd, @option.group, @option.awsid, @option.print)
    end

    def copy_valid?
      raise "You must supply a source and a target. See rudy #{@alias} -h" unless @argv.size >= 2
      raise "You cannot download and upload at the same time" if @option.download && @alias == 'upload'
      true
    end
    def copy
      puts "Rudy Copy".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @option.awsid if @option.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      # Is this more clear?
      @option.recursive && opts[:recursive] = true
      @option.preserve  && opts[:preserve]  = true
      @option.print     && opts[:print]     = true
      
      
      opts[:paths] = @argv
      opts[:dest] = opts[:paths].pop
      
      opts[:task] = :download if @alias == 'download' || @option.download
      opts[:task] = :upload if @alias == 'upload'
      opts[:task] ||= :upload
      
      exit unless @option.print || Annoy.are_you_sure?(:low)
      
      rudy = Rudy::Machines.new(:config => @config, :global => @global)
      rudy.copy(opts)
    end


    def status
      puts "Machine Status".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:state] = @option.state if @option.state
      
      # A nil value forces the @ec2.instances.list to return all instances
      if @option.all
        opts[:state] = :any
        opts[:group] = :any
      end
      
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      rudy = Rudy::Machines.new(:config => @config, :global => @global)
      
      lt = rudy.list(opts[:state], opts[:group], opts[:id]) do |inst|
        puts '-'*60
        puts "Instance: #{inst.awsid.bright} (AMI: #{inst.ami})"
        puts inst.to_s
      end
      puts "No machines running" if !lt || lt.empty?
    end
    alias :machine :status
    
    def console_valid?
      
      @rmach = Rudy::Machines.new(:config => @config, :global => @global)
    end
    
    def console
      puts "Machine Console".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      unless @rmach.any?
        puts "No machines running"
        return
      end
      
      console = @rmach.console(opts[:group], opts[:id])
      
      if console
        puts console
      else
        puts "Console output is not available"
      end
      
    end
    
    
    def machine_create
      puts "Create Machine".bright
      opts = {}
      [:group, :ami, :address, :itype, :keypair].each do |n|
        opts[n] = @option.send(n) if @option.send(n)
      end

      rmach = Rudy::Machines.new(:config => @config, :global => @global)
      # TODO: Print number of machines running. If more than 0, use Annoy.are_you_sure?
      rmach.create(opts) do |inst| # Rudy::AWS::EC2::Instance objects
        puts '-'*60
        puts "Instance: #{inst.awsid.bright} (AMI: #{inst.ami})"
        puts inst.to_s
      end
    
    end
    
    
    def machine_destroy
      puts "Destroy Machine".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      rmach = Rudy::Machines.new(:config => @config, :global => @global)
      exit unless Annoy.are_you_sure?(:low)
      rmach.destroy(opts[:group], opts[:id])
      puts "Done!"
    end
    
  end
end


