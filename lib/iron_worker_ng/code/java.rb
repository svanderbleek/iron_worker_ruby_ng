require_relative 'runtime/java'

module IronWorkerNG
  module Code
    class Java < IronWorkerNG::Code::Base
      def initialize(*args, &block)
        runtime(:java)

        super(*args, &block)
      end
    end
  end
end
