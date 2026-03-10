require_relative 'symple/emitter'
require_relative 'symple/session'

module Symple
  class << self
    # Global Redis client used by Symple components.
    # Defaults to $redis if set, otherwise creates a new connection.
    attr_writer :redis

    def redis
      @redis || $redis || Redis.new
    end

    # Create a new Emitter with sensible defaults.
    #
    # @param options [Hash] emitter options (see Symple::Emitter#initialize)
    # @return [Symple::Emitter]
    def emitter(options = {})
      options[:redis] ||= redis
      Emitter.new(options)
    end

    # Access the session manager.
    #
    # @param options [Hash] session options (see Symple::Session#initialize)
    # @return [Symple::Session]
    def session(options = {})
      options[:redis] ||= redis
      Session.new(options)
    end
  end
end
