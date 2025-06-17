require 'memoist'
require 'faraday'
require 'better-faraday'

module Dogecoin
    class Client
      Error = Class.new(StandardError)
      class ConnectionError < Error; end

      class ResponseError < Error
        def initialize(code, msg)
          @code = code
          @msg = msg
        end

        def message
          "#{@msg} (#{@code})"
        end
      end

      extend Memoist

      def initialize(endpoint)
        @json_rpc_endpoint = URI.parse(endpoint)
      end

      def json_rpc(method, params = [])
        response = connection.post \
          '/',
          { jsonrpc: '1.0', method: method, params: params }.to_json,
          { 'Accept'       => 'application/json',
            'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)

        # MODIFIED: add test log
        puts "1. json_rpc: #{response}"
        puts "2. json_rpc: #{response['error']}"

        response['error'].tap { |e| raise ResponseError.new(e['code'], e['message']) if e }
        response.fetch('result')
      rescue => e
        if e.is_a?(Error)
          # MODIFIED: add test log
          puts "3. json_rpc: #{e}"
          raise e
        elsif e.is_a?(Faraday::Error)
          # MODIFIED: exception handling 'No such mempool transaction'
          # puts "4. json_rpc: #{e}"
          puts "4-2. json_rpc: #{e.response.body}"
          
          response = JSON.parse(e.response.body)
          
          puts "4-3. json_rpc: #{response}"
          puts "4-4. json_rpc: #{response.fetch('error')}"
          error = response.fetch('error')
          puts "4-5. json_rpc: #{error['code']}"
          
          # if error['code'] == -5
          #   puts "Error json_rpc response: #{e.response.body}"

          #   response = {
          #     "result"=>{
          #       "hex"=>"",
          #       "txid"=>"",
          #       "hash"=>"",
          #       "size"=>0,
          #       "vsize"=>0,
          #       "version"=>0,
          #       "locktime"=>0,
          #       "vin"=>[
          #         {
          #           "coinbase"=>"",
          #           "sequence"=>0
          #         }
          #       ],
          #       "vout"=>[
          #         {
          #           "value"=>0,
          #           "n"=>0,
          #           "scriptPubKey"=>{
          #             "asm"=>"",
          #             "hex"=>"",
          #             "reqSigs"=>0,
          #             "type"=>"",
          #             "addresses"=>[
          #               ""
          #             ]
          #           }
          #         }
          #       ],
          #       "blockhash"=>"",
          #       "confirmations"=>0,
          #       "time"=>0,
          #       "blocktime"=>0
          #     },
          #     "error"=>nil,
          #     "id"=>nil
          #   }
          #   response.fetch('result')
          # else
            raise ConnectionError, e
          # end
        else
          # MODIFIED: add test log
          puts "5. json_rpc: #{e}"
          raise Error, e
        end
      end

      def json_rpc_for_withdrawal(method, address, amount)
        response = connection.post \
        '/',
        { jsonrpc: '1.0', method: method, params: [
            address,
            amount.to_f,
        # '', REMOVED! because protocol dosent support this para
        # '', REMOVED! because protocol dosent support this para
        # options[:subtract_fee].to_s == 'true'  # subtract fee from transaction amount.
        ]}.to_json,
        { 'Accept'       => 'application/json',
          'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)
        response['error'].tap { |e| raise ResponseError.new(e['code'], e['message']) if e }
        response.fetch('result')
      rescue => e
        if e.is_a?(Error)
          raise e
        elsif e.is_a?(Faraday::Error)
          raise ConnectionError, e
        else
          raise Error, e
        end
      end

      private

      def connection
        Faraday.new(@json_rpc_endpoint).tap do |connection|
          unless @json_rpc_endpoint.user.blank?
            connection.basic_auth(@json_rpc_endpoint.user,
                                  @json_rpc_endpoint.password)
          end
        end
      end
      memoize :connection
    end
  end


