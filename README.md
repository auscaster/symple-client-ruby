# Symple Client for Ruby

Emit realtime messages and manage sessions from Ruby/Rails to the [Symple](https://github.com/sourcey/symple-server) messaging server via Redis.

Part of the Symple ecosystem:

- **[symple-server](https://github.com/sourcey/symple-server)** — Node.js messaging server
- **[symple-client](https://github.com/sourcey/symple-client)** — JavaScript client (browser & Node.js)

## How It Works

The Symple server uses the `@socket.io/redis-adapter` for horizontal scaling. This client speaks the same Redis pub/sub protocol, allowing your Ruby app to push messages directly to connected Socket.IO clients without HTTP requests to the Symple server.

```
Ruby/Rails  -->  Redis pub/sub  -->  Symple Server  -->  Socket.IO Clients
```

## Install

Add to your Gemfile:

```ruby
gem 'symple-client-ruby', git: 'https://github.com/sourcey/symple-client-ruby'
```

Then `bundle install`.

## Configuration

Set a global Redis connection:

```ruby
# config/initializers/symple.rb
Symple.redis = Redis.new(url: ENV['REDIS_URL'])

# Or if you already have a global $redis:
# Symple.redis = $redis
```

## Emitting Messages

Send messages to specific users (by their Symple user ID / room):

```ruby
emitter = Symple::Emitter.new(
  from: current_user.id.to_s,
  rooms: recipient_ids.map(&:to_s)
)

# Chat message
emitter.emit(
  type: 'message',
  data: 'Hello!',
  chat_id: chat.id,
  sender_id: current_user.id
)

# Event
emitter.emit(
  type: 'event',
  name: 'chat.typing',
  data: { user_id: current_user.id, typing: true }
)
```

### Chaining API

```ruby
Symple::Emitter.new
  .from(user.id.to_s)
  .to(recipient.id.to_s)
  .emit(type: 'message', data: 'Hi!')
```

### Convenience method

```ruby
Symple.emitter(from: user.id.to_s, rooms: ['42', '99'])
  .emit(type: 'event', name: 'refresh', data: { scope: 'contacts' })
```

## Session Management

The Symple server authenticates clients by looking up sessions in Redis at `symple:session:<token>`. Use `Symple::Session` to manage these from Ruby:

```ruby
session = Symple::Session.new
# or: session = Symple.session

# Create a session (e.g. after user login)
session.set(api_token.token, {
  user_id: user.id,
  first_name: user.first_name,
  last_name: user.last_name
}, ttl: 1.week.to_i)

# Read
data = session.get(api_token.token)

# Extend TTL
session.touch(api_token.token, ttl: 1.week.to_i)

# Delete on logout
session.delete(api_token.token)
```

### ActiveRecord Integration

```ruby
class ApiToken < ApplicationRecord
  after_save :update_symple_session
  after_destroy :remove_symple_session

  private

  def update_symple_session
    Symple.session.set(token, {
      user_id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      icon_url: user.icon_url
    }, ttl: expires_in.to_i)
  end

  def remove_symple_session
    Symple.session.delete(token)
  end
end
```

## Redis Key Format

| Key | Purpose |
| --- | --- |
| `symple:session:<token>` | Session data (JSON) |
| `symple#/#` | Pub/sub channel (default namespace) |
| `symple#/chat#` | Pub/sub channel (`/chat` namespace) |

## Requirements

- Ruby >= 3.0
- `redis` gem (>= 4.0)
- `msgpack` gem (>= 1.0)

## License

MIT
