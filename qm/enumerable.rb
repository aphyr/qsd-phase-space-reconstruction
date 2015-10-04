require 'thread'

module Enumerable
  # How many threads to spawn for thread_each. Should be one per processor.
  THREADS = 1

  # Like #each, but executes THREADS threads in parallel.
  def threaded_each
    # Fill queue
    lock = Mutex.new
    tasks = Queue.new
    each do |e|
      tasks << e
    end

    threads = Queue.new

    # Run paths concurrnetly
    THREADS.times do
      threads << Thread.new do
        task = nil
        loop do
          lock.synchronize do
            if tasks.empty?
              Thread.exit
            else
              task = tasks.pop
            end
          end

          yield task if task
        end
      end
    end

    until threads.empty?
      thread = threads.pop
      if thread.respond_to? :join
        # Woot, functioning thread, wait on it.
        thread.join
      else
        # SHOULD NEVER GET HERE.
        puts "Couldn't wait on thread!"
        threads.push thread
      end
    end
  end
end
