# noah-agent
This is a rewrite of the daemon that handles watches in Noah from evented to threaded.

There are two main reasons for this:

- Ease of plugin authoring
- Ease of coding

## Ease of plugin authoring
Under the previous design, plugin authors were required to "speak" EventMachine. This is not a problem except that any library/gem used had to be EM friendly.

I didn't want people to have to worry about that part and instead wanted to allow people to just be able to write a single class that didn't have any special requirements.

Compare the two examples (Old vs. New)

``` ruby

	module Noah::Agents
	  class HttpAgent < Base

	    PREFIX = "http://"
	    NAME = self.class.to_s
	    DEFAULT_CONCURRENCY = 50

	    def work!(ep, message)
		logger.info("Sending message to (#{ep})")
		http = EM::HttpRequest.new(ep, :connection_timeout => 2, :inactivity_timeout => 2).post :body => message
		http.callback {
		  logger.info("Message posted to #{ep} successfully")
		}
		http.errback {
		  logger.error("Something went wrong with #{ep}")
		}
	    end

	  end
	end

```

``` ruby

	class FooWorker
	  include NoahAgent::Worker
	  ENDPOINT_PATTERN = "fooworker://"

	  def work(e,m)
	   # Define how to handle your work
	    puts "Endpoint: #{e}. Message #{m}"
	  end
	end

```

To me, the second is much more legible and easy to understand. Additionally, I've done away with the subclassing and instead moved to includes. Requiring the subclassing was rather arrogant on my part.

This comes with a downside though. If you write blocking code, that thread will block. However, the new model uses a pool of workers so in the worst case, we can allocate more workers for that particular worker class.

## Ease of coding
This is more for me than end users. The reason this change is took so long is that previously, the daemon was shipped as a part of Noah itself. It used the Noah models directly to look up watchers.
Under the new version, the daemon will actually communicate with Redis over HTTP to pull the watches. This leads to less fragility.

# Other benefits
There are some additional benefits as well. Testing the agent will be much easier. Additionally, this new design will allow more flexible control over per-worker configuration.
The idea is that now you can spin up multiple instances of the agent on different boxes (if need be) to handle the watches. One instance does `http://` while another might do `amqp://`.

# TODO
- Finish up exception handling across the board.
- Write the so-called easy tests
- Finish out cli options
- Make per-worker tunables via CLI and a config file
- Finish the plugin detection system
- A bunch of other stuff

# Usage
Right now it makes the assumption that everything is running on localhost (redis and noah). It does, however, work. Feel free to poke around if you like.

This is my first real attempt at using Celluloid and Actors seriously. Any advice, comments or rude remarks are more than welcome!
