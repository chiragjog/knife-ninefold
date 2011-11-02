#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
    class NinefoldServerList < Knife

      include Knife::NinefoldBase

      banner "knife ninefold server list (options)"

      def run
        $stdout.sync = true

        validate!

        server_list = [
          ui.color('Instance ID', :bold),
          ui.color('Display Name', :bold),
          ui.color('Private IP Address', :bold),
          ui.color('Public IP Address', :bold),
          ui.color('Password', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
	  ui.color('Service Offering', :bold),
          ui.color('State', :bold)
        ]
        connection.servers.all.each do |server|
	  puts("\n")
	  public_ip = ""
          server_list << server.id.to_s
          server_list << server.displayname.to_s
          server_list << server.ipaddress.to_s
          connection.addresses.all.each do |ipaddress|
            if ipaddress.virtualmachineid == server.id
		public_ip = ipaddress.ipaddress
		break
	    end
	  end
          server_list << public_ip.to_s
          server_list << server.password.to_s
          server_list << server.flavor_id.to_s
          server_list << server.templatedisplaytext.to_s
          server_list << server.serviceofferingname.to_s
          #server_list << server.key_name.to_s
          server_list << begin
            state = server.state.to_s.downcase
            case state
            when 'shutting-down','terminated','stopping','stopped'
              ui.color(state, :red)
            when 'pending'
              ui.color(state, :yellow)
            else
              ui.color(state, :green)
            end
          end
        end
        puts ui.list(server_list, :columns_across, 8)

      end
    end
  end
end


