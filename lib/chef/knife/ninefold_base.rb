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

require 'chef/knife'

class Chef
  class Knife
    module NinefoldBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :ninefold_access_key_id,
            :short => "-A ID",
            :long => "--ninefold-access-key-id KEY",
            :description => "Your Ninefold Access Key ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:ninefold_access_key_id] = key }

          option :ninefold_secret_access_key,
            :short => "-K SECRET",
            :long => "--ninefold-secret-access-key SECRET",
            :description => "Your Ninefold API Secret Access Key",
            :proc => Proc.new { |key| Chef::Config[:knife][:ninefold_secret_access_key] = key }

          option :ninefold_api_endpoint,
            :long => "--ninefold-api-endpoint ENDPOINT",
            :description => "Your Ninefold API endpoint",
            :proc => Proc.new { |endpoint| Chef::Config[:knife][:ninefold_api_endpoint] = endpoint }

          option :region,
            :long => "--region REGION",
            :description => "Your Ninefold region",
            :proc => Proc.new { |region| Chef::Config[:knife][:region] = region }
          
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider => 'Ninefold',
            :ninefold_compute_key => Chef::Config[:knife][:ninefold_access_key_id],
            :ninefold_compute_secret => Chef::Config[:knife][:ninefold_secret_access_key],
            :ninefold_api_url => Chef::Config[:knife][:ninefold_api_endpoint]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def validate!(keys=[:ninefold_access_key_id, :ninefold_secret_access_key, :ninefold_api_endpoint])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provided a valid '#{pretty_key}' value."
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

    end
  end
end


