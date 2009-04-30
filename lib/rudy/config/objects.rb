

class Rudy::Config
  class Machines < Caesars; end
  class Defaults < Caesars; end
  class Networks < Caesars; end
  class Controls < Caesars; end
  class Services < Caesars; end
  # Modify the SSH command available in routines. The default
  # set of commands is defined by Rye::Cmd (Rudy executes all
  # SSH commands via Rye). 
  #
  # NOTE: We allow people to define their own keywords. It is
  # important that new keywords do not conflict with existing
  # Rudy keywords. Strange things may happen!
  class Commands < Caesars
    @@processed = false
    forced_array :allow
    forced_array :deny
    def init
      # We can't process the Rye::Cmd commands here because the
      # DSL hasn't been parsed yet so Rudy::Config.postprocess
      # called the following postprocess method after parsing.
    end
    # Process the directives specified in the commands config.
    # NOTE: This affects the processing of the routines config
    # which only works if commands is parsed first. This works
    # naturally if each config has its own file b/c Rudy loads
    # files via a glob (globs are alphabetized and "commands"
    # comes before "routines"). 
    #
    # That's obviously not good enough but for now commands
    # configuration MUST be put before routines. 
    def postprocess
      return false if @@processed
      @@processed = true  # Make sure this runs only once
      
      # Parses:
      # commands do
      #   allow :kill 
      #   allow :custom_script, '/full/path/2/custom_script'
      # end
      # 
      # * Tells Routines to force_array on the command name.
      # This is important b/c of the way we parse commands 
      self.allow.each do |cmd|
        cmd, path, *args = *cmd
        path ||= cmd # If no path, we can assume cmd is in the remote path
        args.collect! do |arg| 
          if ([Symbol, String] & [arg.class]).empty?
            raise ArgumentError, 
                  "Found #{arg.class} for #{cmd} (Symbols, Strings only)"
          end
          arg.is_a?(Symbol) ? ":#{arg}" : "'#{arg}'"
        end
        hard_args = args.empty? ? "*args" : "#{args.join(', ')}, *args"
        Rudy::Config::Routines.forced_array cmd
        Rye::Cmd.module_eval %Q{
          def #{cmd}(*args); cmd(:'#{path}', #{hard_args}); end
        }
      end
      # We deny commands by telling routines to not parse the given keywords
      self.deny.each do |cmd|
        Rudy::Config::Routines.forced_ignore cmd.first # cmd is a forced array
        # We don't remove the method from Rye:Cmd because we 
        # may need elsewhere in Rudy. Forced ignore ensures
        # the config is not stored anyhow.
      end
      raise Caesars::Config::ForceRefresh.new(:routines)
    end
  end
  
  class Accounts < Caesars
    def valid?
      (!aws.nil? && !aws.accesskey.nil? && !aws.secretkey.nil?) &&
      (!aws.account.empty? && !aws.accesskey.empty? && !aws.secretkey.empty?)
    end
  end
  
  class Routines < Caesars
    
    # Disk routines
    forced_hash :create
    forced_hash :destroy
    forced_hash :restore
    forced_hash :mount
    
    # Remote scripts
    forced_hash :before
    forced_hash :before_local
    forced_hash :after
    forced_hash :after_local
    
    # Version control systems
    forced_hash :git
    forced_hash :svn
    
    def init
      
    end
    
    # Add remote shell commands to the DSL as forced Arrays. 
    # Example:
    #     ls :a, :l, "/tmp"  # => :ls => [[:a, :l, "/tmp"]]
    #     ls :o              # => :ls => [[:a, :l, "/tmp"], [:o]]
    # NOTE: Beware of namespace conflicts in other areas of the DSL,
    # specifically shell commands that have the same name as a keyword
    # we want to use in the DSL. This includes commands that were added
    # to Rye::Cmd before Rudy is 'require'd. 
    Rye::Cmd.instance_methods.sort.each do |cmd|
      forced_array cmd
    end
    
  end
end