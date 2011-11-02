# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2011 Clogeny Technologies.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/ninefold_base'

class Chef
  class Knife
    class NinefoldServerCreate < Knife

      include Knife::NinefoldBase

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ninefold server create (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server (m1.small, m1.medium, etc)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f }

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The AMI for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i }

      option :availability_zone,
        :short => "-Z ZONEID",
        :long => "--availability-zone ZONEID",
        :description => "The Availability Zone id ",
        :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node",
        :proc => Proc.new { |key| Chef::Config[:knife][:chef_node_name] = key }


      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true

        validate!

        connection = Fog::Compute.new(
          :provider => 'Ninefold',
          :ninefold_compute_key => Chef::Config[:knife][:ninefold_access_key_id],
          :ninefold_compute_secret => Chef::Config[:knife][:ninefold_secret_access_key],
          :ninefold_api_url => Chef::Config[:knife][:ninefold_api_endpoint]
        )

        server_def = {
          :image_id => locate_config_value(:image),
          :flavor_id => locate_config_value(:flavor),
          :zoneid => Chef::Config[:knife][:availability_zone],
	  :displayname => Chef::Config[:knife][:chef_node_name],
	  :name => Chef::Config[:knife][:chef_node_name]
        }
	ipaddress_def = {
	  :zoneid => Chef::Config[:knife][:availability_zone]
	}
        server = connection.servers.create(server_def)
	if server.password.nil?
	   server.password = 'Password01'
	end
	puts("Server Name:" + server.name + "\n")
	puts("Server Password:" + server.password + "\n")

        msg_pair("Instance ID", server.id)
        msg_pair("Flavor", server.flavor_id)
        msg_pair("Image", server.image_id)
        msg_pair("Region", server.zonename)
        msg_pair("Password", server.password)

        print "\n#{ui.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        msg_pair("Private IP Address", server.ipaddress)
	ipaddress = connection.addresses.create(ipaddress_def)
        print "\n#{ui.color("Waiting for ip address to be allocated", :magenta)}"
        ipaddress.wait_for { print "."; ready? }
	#Enable Static Nat
	ipaddress.enable_static_nat(server)

        public_ip = ipaddress.ipaddress	

	# Create Ip port forwarding rule for SSH
	port_fwd_rule_def = {
		'protocol' => 'TCP',
		'ipaddressid' => ipaddress.id,
		'startport' => 22,
		'endport' => 22
	}
	port_fwd = connection.ip_forwarding_rules.create(port_fwd_rule_def)
        print "\n#{ui.color("Waiting for Port Forward rule to be allocated", :magenta)}"
        port_fwd.wait_for { print "."; ready? }
	
	server.nic[0]['ipaddress'] = public_ip
	server.hostname = public_ip
        msg_pair("Private IP Address", server.ipaddress)
        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        print(".") until tcp_test_ssh(public_ip) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

        bootstrap_for_node(server).run

        puts "\n"
        msg_pair("Instance ID", server.id.to_s)
        msg_pair("Flavor", server.flavor_id.to_s)
        msg_pair("Image", server.image_id.to_s)
        msg_pair("Region", server.zonename.to_s)
        msg_pair("Password", server.password.to_s)
        msg_pair("IP Address", server.ipaddress.to_s)
        msg_pair("Public IP Address", public_ip.to_s)
        msg_pair("Name", server.displayname.to_s)

      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [server.ipaddress.to_s]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = 'root'
	bootstrap.config[:ssh_password] = 'Password01'
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id.to_s
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = '0.10.4' 
        bootstrap.config[:distro] = "ubuntu10.04-gems"
        bootstrap.config[:template_file] = false
        bootstrap.config[:environment] = config[:environment]
        bootstrap
      end

      def image
        @imageid ||= connection.images.get(locate_config_value(:image))
      end

      def validate!

        super([:image, :ninefold_access_key_id, :ninefold_secret_access_key, :ninefold_api_endpoint])

        if image.nil?
          ui.error("You have not provided a valid image value.")
          exit 1
        end
      end

    end
  end
end
