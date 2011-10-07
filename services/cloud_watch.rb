

class Service::CloudWatch < Service
  def receive_logs
    data_points = prepare(payload[:events], settings[:metric_name], settings[:regex])
    return if data_points.empty?

    if settings[:metric_namespace].present?
      metric_namespace = settings[:metric_namespace]
    else
      metric_namespace = 'Papertrail'
    end

    cloudwatch_post(metric_namespace, data_points)
  end

  def aws_connection
    @aws_connection ||= begin
      http.dup.tap do |c|
        c.builder.insert(0, AwsAuthentication, settings[:aws_access_key_id], settings[:aws_secret_access_key])
        c.builder.insert(1, Faraday::Request::UrlEncoded)
        c.builder.insert(3, Faraday::Response::RaiseError)
      end
    end
  end

  def prepare(events, name, regex)
    unless regex.present?
      # count all events as a single data point
      return [{
        :metric_name => name,
        :value => events.length,
        :timestamp => Time.now.utc.strftime('%FT%XZ')
      }]
    end

    extract_data_points(name, events, Regexp.new(regex))
  end

  def extract_data_points(name, events, regex)
    data_points = []

    events.each do |event|
      value = nil

      match_data = event[:message].match(regex)
      # does not match event
      next unless match_data

      # use extracted value or 1 (no regex backreference provided)
      value = match_data[1] ? match_data[1].to_i : 1

      data_points << {
        :metric_name => name,
        :value => value,
        :timestamp => event[:received_at]
      }
    end

    data_points
  end

  def cloudwatch_post(namespace, data_points)
    body = {}
    data_points.each_with_index do |data_point, idx|
      key_prefix = "MetricData.member.#{idx + 1}"

      body["#{key_prefix}.MetricName"] = data_point[:metric_name]
      body["#{key_prefix}.Value"]      = data_point[:value]
      body["#{key_prefix}.Timestamp"]  = data_point[:timestamp]
    end

    body['Action']    = 'PutMetricData'
    body['Version']   = '2010-08-01'
    body['Namespace'] = namespace

    aws_connection.post 'https://monitoring.amazonaws.com/' do |req|
      req.body = body
    end
  end

  # Faraday middleware to perform AWS authentication
  class AwsAuthentication < Faraday::Middleware
    dependency do
      require 'openssl'
      require 'base64'
    end

    def initialize(app, access_key_id, secret_access_key)
      @app               = app
      @access_key_id     = access_key_id
      @secret_access_key = secret_access_key
    end

    def call(env)
      if env[:method] == :get
        params = Faraday::Utils::ParamsHash.new
        params.merge_query(env[:url].query)
        add_aws_signature(env, params)
        env[:url].query = params.to_query
      else
        add_aws_signature(env, env[:body])
      end

      @app.call(env)
    end

    def add_aws_signature(env, params_hash)
      params_hash['AWSAccessKeyId']   = @access_key_id
      params_hash['SignatureVersion'] = 2
      params_hash['SignatureMethod']  = 'HmacSHA256'
      params_hash['Timestamp']        = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

      string_to_sign = [ env[:method].to_s.upcase, env[:url].host.to_s.downcase,
        env[:url].path, canonical_query_string(params_hash) ].join("\n")

      digest = OpenSSL::Digest::Digest.new('sha256')
      signature = OpenSSL::HMAC.digest(digest, @secret_access_key, string_to_sign)
      params_hash['Signature'] = Base64.encode64(signature).strip
    end

    def canonical_query_string(params)
      params.sort.collect { |(k,v)| "#{Faraday::Utils.escape(k)}=#{Faraday::Utils.escape(v)}"}.join('&')
    end
  end
end