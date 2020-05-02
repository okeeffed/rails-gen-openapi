require "dry/monads"
require "dry/monads/do"

module FP
  class RoutesFile
    class << self
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def call(file)
        values = yield read(file)
        Success(values)
      end

      def read(file)
        # returns Success(values) or Failure(:invalid_data)
        filepath = File.join(File.dirname(__dir__), file)
        file = File.read(filepath)
        Success(file)
      rescue
        Failure("Failed to parse file")
      end

      # def create_account(account_values)
      #   # returns Success(account) or Failure(:account_not_created)
      # end

      # def create_owner(account, owner_values)
      #   # returns Success(owner) or Failure(:owner_not_created)
      # end
    end
  end
end
