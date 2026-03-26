require 'redis'
require 'json'
require 'securerandom'

module Symple
  class Emitter
    # Create a new Symple v4 emitter.
    #
    # Publishes Symple protocol messages to the server via Redis pub/sub.
    # The Symple server subscribes to the channel and routes messages
    # to connected WebSocket peers.
    #
    # @param options [Hash]
    # @option options [Redis] :redis - Redis client instance (defaults to $redis)
    # @option options [String] :channel - Redis pub/sub channel (default: 'symple:broadcast')
    # @option options [String] :from - sender address (e.g. 'user|id')
    # @option options [Array<String>] :rooms - target rooms
    def initialize(options = {})
      @redis = options[:redis] || $redis || Redis.new
      @channel = options[:channel] || 'symple:broadcast'
      @from = options[:from]
      @rooms = options[:rooms] || []
    end

    # Emit a Symple message via Redis pub/sub.
    #
    # @param message [Hash] Symple protocol message
    # @return [self]
    def emit(message)
      message = message.dup
      message[:id] ||= SecureRandom.hex(8)
      message[:type] ||= 'message'
      message[:from] = @from if @from
      message[:to] = @rooms unless @rooms.empty?

      @redis.publish(@channel, JSON.generate(message))
      self
    end

    # Send a message to specific peers/rooms.
    #
    # @param data [Hash] message payload
    # @param to [String, Array<String>] recipient address or room(s)
    # @return [self]
    def send(data, to: nil)
      message = {
        type: 'message',
        data: data
      }
      message[:to] = to if to
      emit(message)
    end

    # Send a presence message.
    #
    # @param peer_data [Hash] peer data (user, name, online, etc.)
    # @return [self]
    def send_presence(peer_data)
      emit({
        type: 'presence',
        data: peer_data
      })
    end

    # Send an event message.
    #
    # @param subtype [String] event subtype
    # @param data [Hash] event data
    # @return [self]
    def send_event(subtype, data = {})
      emit({
        type: 'event',
        subtype: subtype,
        data: data
      })
    end

    # Set the sender address.
    #
    # @param addr [String] sender address (e.g. 'user|id')
    # @return [self]
    def from(addr)
      raise ArgumentError, 'Address must be a string' unless addr.is_a?(String)
      @from = addr
      self
    end

    # Add a target room.
    #
    # @param room [String] room name or user address
    # @return [self]
    def to(room)
      raise ArgumentError, 'Room must be a string' unless room.is_a?(String)
      @rooms << room unless @rooms.include?(room)
      self
    end
    alias_method :in, :to

    # Store a session token in Redis for authentication.
    #
    # @param token [String] session token
    # @param data [Hash] session data (user, permissions, etc.)
    # @param ttl [Integer] time-to-live in seconds (nil for no expiry)
    # @return [self]
    def create_session(token, data, ttl: nil)
      key = "symple:session:#{token}"
      @redis.set(key, JSON.generate(data))
      @redis.expire(key, ttl) if ttl
      self
    end

    # Remove a session token from Redis.
    #
    # @param token [String] session token
    # @return [self]
    def destroy_session(token)
      @redis.del("symple:session:#{token}")
      self
    end
  end
end
