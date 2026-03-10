require 'redis'
require 'json'

module Symple
  # Manages Symple sessions in Redis.
  #
  # Sessions are stored as JSON at `symple:session:<token>` and are used
  # by the Symple server to authenticate connecting clients.
  #
  # Usage:
  #   session = Symple::Session.new(redis: $redis)
  #   session.set('my-token', { user_id: 1, name: 'Alice' }, ttl: 3600)
  #   session.get('my-token')  # => { "user_id" => 1, "name" => "Alice" }
  #   session.delete('my-token')
  #
  class Session
    KEY_PREFIX = 'symple:session:'.freeze

    # @param options [Hash]
    # @option options [Redis] :redis - Redis client (defaults to $redis)
    def initialize(options = {})
      @redis = options[:redis] || $redis || Redis.new
    end

    # Store a session in Redis.
    #
    # @param token [String] session token
    # @param data [Hash] session data (user_id, name, etc.)
    # @param ttl [Integer, nil] TTL in seconds (nil = no expiry)
    def set(token, data, ttl: nil)
      key = session_key(token)
      @redis.set(key, data.to_json)
      @redis.expire(key, ttl.to_i) if ttl && ttl > 0
    end

    # Retrieve a session from Redis.
    #
    # @param token [String] session token
    # @return [Hash, nil] parsed session data or nil
    def get(token)
      value = @redis.get(session_key(token))
      return nil unless value
      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    # Delete a session from Redis.
    #
    # @param token [String] session token
    def delete(token)
      @redis.del(session_key(token))
    end

    # Extend a session's TTL.
    #
    # @param token [String] session token
    # @param ttl [Integer] new TTL in seconds
    def touch(token, ttl:)
      @redis.expire(session_key(token), ttl.to_i) if ttl && ttl > 0
    end

    # Check if a session exists.
    #
    # @param token [String] session token
    # @return [Boolean]
    def exists?(token)
      @redis.exists?(session_key(token))
    end

    private

    def session_key(token)
      "#{KEY_PREFIX}#{token}"
    end
  end
end
