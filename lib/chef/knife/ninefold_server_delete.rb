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
    class NinefoldServerDelete < Knife

      include Knife::NinefoldBase

      banner "knife ninefold server delete SERVER [SERVER] (options)"

      def run

        validate!

        @name_args.each do |instance_id|
          server = connection.servers.get(instance_id)

          msg_pair("Instance ID", server.id)
          msg_pair("Instance Name", server.name)
          msg_pair("IP Address", server.ipaddress)

          puts "\n"
          confirm("Do you really want to delete this server")

          server.destroy

          ui.warn("Deleted server #{server.id}")
	  connection.addresses.each do |ipaddress|
            if ipaddress.virtualmachineid == server.id
              ipaddress.destroy
              ui.warn("Released IP address #{ipaddress.id}")
              break 
            end
          end
        end
      end

    end
  end
end

