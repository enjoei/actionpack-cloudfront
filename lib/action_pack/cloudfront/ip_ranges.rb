module ActionPack
  module Cloudfront
    module IpRanges

      class Range
        attr_reader :ip_prefix, :region

        def initialize(attrs)
          @ip_prefix = attrs['ip_prefix'] || attrs['ipv6_prefix']
          @region = attrs['region']
        end

        def ipaddr
          IPAddr.new(ip_prefix)
        end
      end

      def trusted_proxies
        incapsula_proxies + aws_proxies + ActionDispatch::RemoteIp::TRUSTED_PROXIES
      end

      def incapsula_proxies
        proxies = [
          '199.83.128.0/21', '198.143.32.0/19', '149.126.72.0/21', '103.28.248.0/22', '45.64.64.0/22',
          '185.11.124.0/22', '192.230.64.0/18', '107.154.0.0/16', '45.60.0.0/16', '45.223.0.0/16',
          '2a02:e980::/29'
        ]

        proxies.map { |ip_prefix| IPAddr.new(ip_prefix) }
      end

      def aws_proxies
        ip_ranges.map(&:ipaddr).uniq
      end

      def ip_ranges
        @ip_ranges ||= begin
          data = ip_data
          prefixes = data['prefixes']
          prefixesv6 = data['ipv6_prefixes']
          (prefixes + prefixesv6).map do |attrs|
            Range.new(attrs)
          end
        end
      end

      def ip_data
        Timeout.timeout(5) do
          uri = URI('https://ip-ranges.amazonaws.com/ip-ranges.json')
          res = Net::HTTP.get(uri)
          JSON.parse(res)
        end
      rescue
        backup_json = File.join File.dirname(__FILE__), 'ip-ranges.json'
        JSON.parse File.read(backup_json)
      end

      extend self

    end
  end
end


