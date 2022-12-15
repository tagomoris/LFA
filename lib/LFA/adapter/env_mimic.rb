# frozen_string_literal: true

require 'delegate'

module LFA
  class Adapter
    module Environment
      def self.setup
        original_verbose = $VERBOSE
        begin
          $VERBOSE = nil
          ENV = EnvMimic.new
        ensure
          $VERBOSE = original_verbose
        end
      end

      class EnvMimic < Delegator
        def initialize
          @is_active = false
          @box = nil
          @env = ENV
        end    

        def __getobj__
          if @is_active
            @box
          else
            @env
          end
        end

        def __setobj__(obj)
          @box = obj
        end

        def mimic!(env)
          @box = env.dup
          @is_active = true
          yield
        ensure
          @box = nil
          @is_active = false
        end
      end
    end
  end
end
