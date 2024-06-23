## Debugging

### Locally

You can debug your instance of slack-gamebot with a built-in console.

```
$ ./script/console

2.3.1 :001 > Team.count
=> 3
```

### Silence Mongoid Logger

If Mongoid logging is annoying you.

```ruby
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
```
