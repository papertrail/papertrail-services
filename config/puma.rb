workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 3)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

if ['production', 'staging'].include?(ENV['RACK_ENV'])
  on_worker_boot do
    if $metriks_reporters && $metriks_reporters.is_a?(Array)
      $metriks_reporters.each do |reporter|
        reporter.restart
      end
    end
  end
end

Rack::Timeout.timeout = 60
