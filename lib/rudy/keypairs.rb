
module Rudy
  class KeyPairs
    include Rudy::Huxtable
    
    
    def create(n=nil, opts={})
      
      if !n && has_root_keypair?
        raise "A root keypair is already defined for #{current_machine_group}" 
      end
      
      n ||= name(n)
        
      opts = {
        :force => false
      }.merge(opts)
      
      delete_pk(n) if opts[:force] == true && File.exists?(self.path(n))
      raise "Private key already exists: #{self.path(n)}" if File.exists?(self.path(n))
      
      kp = @@ec2.keypairs.create(n)
      raise "Error creating #{n} keypair" unless kp.is_a?(Rudy::AWS::EC2::KeyPair)
      
      @logger.puts "Writing #{self.path(n)}"
      Rudy::Utils.write_to_file(self.path(n), kp.private_key, 'w')
      
      @logger.puts "Writing #{self.public_path(n)}"
      Rudy::Utils.write_to_file(self.public_path(n), kp.public_key, 'w')
      
      @logger.puts "Changing permissions to #{self.public_path(n)}"
      Rudy::Utils.write_to_file(self.public_path(n), kp.public_key, 'w')
      
      @logger.puts "NOTE: If you move #{self.path(n)} you need to also update your Rudy machines config."
      
      kp
    end
    
    def destroy(n=nil)
      n ||= name(n)
      raise "KeyPair #{n} doesn't exist" unless exists?(n)
      @logger.puts "No private key file: #{self.path(n)}. Continuing..." unless File.exists?(self.path(n))
      @logger.puts "Unregistering KeyPair with Amazon"
      ret = @@ec2.keypairs.destroy(n)
      ret = delete_files(n) if ret # only delete local file if remote keypair is successfully destroyed
      ret
    end
    
    def list(n=nil, &each_object)
      n &&= [n]
      keypairs = @@ec2.keypairs.list(n)
      keypairs.each { |n,kp| each_object.call(kp) } if each_object
      keypairs
    end
    
    def list_as_hash(n=nil, &each_object)
      n &&= [n]
      keypairs = @@ec2.keypairs.list_as_hash(n)
      keypairs.each_pair { |n,kp| each_object.call(kp) } if each_object
      keypairs
    end
    
    def exists?(n=nil)
      n ||= name(n)
      @@ec2.keypairs.exists?(n)
    end
    
    def any?(n=nil)
      n ||= name(n)
      @@ec2.keypairs.any?    end
    
    def name(n=nil)
      n ||= current_machine_group
      "key-#{n}"
    end
      
    def path(n=nil)
      n ||= name(n)
      File.join(self.config_dirname, "#{n}.private")
    end
    
    def public_path(n=nil)
      n ||= name(n)
      File.join(self.config_dirname, "#{n}.pub")
    end
    
    def has_root_keypair?
      path = user_keypairpath(:root)
      (!path.nil? && !path.empty?)
    end
    

    # We use the base file name to determine the registered keypair name.
    def KeyPairs.path_to_name(path)
      return unless path
      return path unless File.exists?(path)
      File.basename(path).gsub('.private', '')
    end
    
  private
    def delete_files(n=nil)
      n ||= name(n)
      return false unless File.exists?(self.path(n))
      @logger.puts "Deleting #{self.path(n)}"
      (File.unlink(self.path(n)) > 0)      # raise exception on error. handle?
      
      return false unless File.exists?(self.public_path(n))
      @logger.puts "Deleting #{self.public_path(n)}"
      (File.unlink(self.public_path(n)) > 0)
    end

  end
end