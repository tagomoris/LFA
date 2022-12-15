# frozen_string_literal: true

require 'delegate'

module LFA
  class Adapter
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
