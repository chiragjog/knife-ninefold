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
    class NinefoldFlavorList < Knife

      include Knife::NinefoldBase

      banner "knife ninefold flavor list (options)"

      def run

        validate!

        flavor_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('RAM', :bold),
          ui.color('Disk', :bold),
          ui.color('CPU Speed', :bold),
          ui.color('CPU cores', :bold)
        ]
        connection.flavors.sort_by(&:id).each do |flavor|
          flavor_list << flavor.id.to_s
          flavor_list << flavor.name
          flavor_list << "#{flavor.memory.to_s}"
          flavor_list << "#{flavor.storagetype.to_s} GB"
          flavor_list << flavor.cpuspeed.to_s
          flavor_list << flavor.cpunumber.to_s
        end
        puts ui.list(flavor_list, :columns_across, 6)
      end
    end
  end
end
