

module Rudy
  class Machine < Storable 
    extend Rudy::Metadata
    
    domain :rudy_state
    
    class << self
      
      def data
        %Q{
a few lines
of content to
run regexps
        }
      end
      
      def list
        [1]
      end
      
      def list_as_hash
        {}
      end
      
      def get
        'nil'
      end
      
      def find
      end
      
    end
    
  end
end