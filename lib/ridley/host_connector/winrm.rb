module Ridley
  module HostConnector
    # @author Kyle Allan <kallan@riotgames.com>
    class WinRM
      autoload :Worker, 'ridley/host_connector/winrm/worker'

      class << self
        # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
        # @param [Hash] options
        def start(nodes, options = {}, &block)
          runner = new(nodes, options)
          result = yield runner
          runner.terminate

          result
        ensure
          runner.terminate if runner && runner.alive?
        end
      end

      include Celluloid
      include Celluloid::Logger

      attr_reader :nodes
      attr_reader :options

      EMBEDDED_RUBY_PATH = "C:\\opscode\\chef\\embedded\\bin\\ruby".freeze

      # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
      # @param [Hash] options
      def initialize(nodes, options = {})
        @nodes = Array(nodes)
        @options = options
      end

      # @param [String] command
      #
      # @return [Array]
      def run(command)
        workers = Array.new
        futures = self.nodes.collect do |node|
          workers << worker = Worker.new(node.public_hostname, self.options.freeze)
          worker.future.run(command)
        end

        Ridley::HostConnector::ResponseSet.new.tap do |response_set|
          futures.each do |future|
            status, response = future.value
            response_set.add_response(response)
          end
        end
      ensure
        workers.map(&:terminate)
      end

      # Executes a chef-client run on the nodes
      # 
      # @return [#run]
      def chef_client
        run("chef-client")
      end

      # Executes a copy of the encrypted_data_bag_secret to the nodes
      #
      # @param [String] encrypted_data_bag_secret_path
      #   the path to the encrypted_data_bag_secret
      # 
      # @return [#run]
      def put_secret(encrypted_data_bag_secret_path)
        secret  = File.read(encrypted_data_bag_secret_path).chomp
        command = "echo #{secret} > C:\\chef\\encrypted_data_bag_secret"
        run(command)
      end

      # Executes a provided Ruby script in the embedded Ruby installation
      # 
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      # 
      # @return [#run]
      def ruby_script(command_lines)
        command = "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\""
        run(command)
      end
    end
  end
end
