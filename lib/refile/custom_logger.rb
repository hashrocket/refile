require "rack/body_proxy"
module Refile
  class CustomLogger
    LOG_FORMAT = %(%s: [%s] %s "%s%s" %d %0.1fms\n)

    def initialize(app, prefix, logger_proc)
      @app, @prefix, @logger_proc = app, prefix, logger_proc
    end

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      body = Rack::BodyProxy.new(body) { log(env, status, began_at) }
      [status, header, body]
    end

  private

    def log(env, status, began_at)
      now = Time.now
      logger.info format(
        LOG_FORMAT,
        @prefix,
        now.strftime("%F %T %z"),
        env["REQUEST_METHOD"],
        env["PATH_INFO"],
        env["QUERY_STRING"].empty? ? "" : "?" + env["QUERY_STRING"],
        status.to_s[0..3],
        (now - began_at) * 1000
      )
    end

    def logger
      @logger ||= @logger_proc.call
      @logger || fallback_logger
    end

    def fallback_logger
      @fallback_logger ||= Logger.new(nil)
    end
  end
end
