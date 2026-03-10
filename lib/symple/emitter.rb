require 'redis'
require 'msgpack'
require 'json'
require 'securerandom'

module Symple
  class Emitter
    module Type
      EVENT = 2
      BINARY_EVENT = 5
    end

    FLAGS = %w(json volatile broadcast).freeze

    # Create a new Symple emitter.
    #
    # @param options [Hash]
    # @option options [Redis] :redis - Redis client instance (defaults to $redis)
    # @option options [String] :uid - unique ID for this node (default: 'ruby')
    # @option options [String] :nsp - Socket.IO namespace (default: '/')
    # @option options [String] :from - sender address
    # @option options [Array<String>] :rooms - target rooms/user IDs
    # @option options [Hash] :flags - Socket.IO flags
    def initialize(options = {})
      @redis = options[:redis] || $redis || Redis.new
      @uid = options[:uid] || 'ruby'
      @nsp = options[:nsp] || '/'
      @from = options[:from]
      @rooms = options[:rooms] || []
      @flags = options[:flags] || {}

      # Custom emit flag tells the Redis adapter to rebroadcast
      @flags[:emit] = true
    end

    # Emit a message via Redis pub/sub to the Symple server.
    #
    # @param args [Array] message data (optionally preceded by an event name string)
    # @return [self]
    def emit(*args)
      packet = encode_packet(*args)
      packed = MessagePack.pack([@uid, packet, { rooms: @rooms, flags: @flags }])

      channel = "symple##{@nsp}#"
      @redis.publish(channel, packed)

      self
    end

    # Set the sender address.
    #
    # @param addr [String] sender address (e.g. "user_id")
    # @return [self]
    def from(addr)
      raise ArgumentError, 'Address must be a string' unless addr.is_a?(String)
      @from = addr
      self
    end

    # Add a target room/user.
    #
    # @param room [String] room name or user ID
    # @return [self]
    def to(room)
      raise ArgumentError, 'Address must be a string' unless room.is_a?(String)
      @rooms << room unless @rooms.include?(room)
      self
    end
    alias_method :in, :to

    # Set the Socket.IO namespace.
    #
    # @param nsp [String] namespace (e.g. '/chat')
    # @return [self]
    def of(nsp)
      raise ArgumentError, 'Namespace must be a string' unless nsp.is_a?(String)
      @nsp = nsp.to_s
      self
    end

    FLAGS.each do |flag|
      define_method(flag) {
        @flags.merge!(flag.to_sym => true)
        self
      }
    end

    protected

    def has_binary?(args)
      args.select { |x| x.is_a?(String) }.any? { |str|
        str.encoding == Encoding::ASCII_8BIT && !str.ascii_only?
      }
    end

    def encode_packet(*args)
      # If multiple arguments and the first is a string, use it as the event name
      event = args.length > 1 && args.first.is_a?(String) ? args.shift : 'message'

      # Set packet type based on binary content
      type = has_binary?(args) ? Type::BINARY_EVENT : Type::EVENT

      # Build the message from remaining args
      data = args.first
      if data.is_a?(Hash) && data.include?(:data)
        message = data
      else
        message = { data: data }
      end

      # Set required fields
      message[:id] ||= SecureRandom.hex(16)
      message.merge!(to: @rooms) if @rooms
      message.merge!(from: @from) if @from

      # Return Socket.IO encoded packet
      {
        type: type,
        data: [event, message],
        nsp: @nsp
      }
    end
  end
end
