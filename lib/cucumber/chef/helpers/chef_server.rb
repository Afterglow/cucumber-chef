################################################################################
#
#      Author: Stephen Nelson-Smith <stephen@atalanta-systems.com>
#      Author: Zachary Patten <zachary@jovelabs.com>
#   Copyright: Copyright (c) 2011-2012 Atalanta Systems Ltd
#     License: Apache License, Version 2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
################################################################################

module Cucumber::Chef::Helpers::ChefServer

################################################################################

  def chef_server_node_destroy(name)
    (Chef::Node.load(name).destroy rescue nil)
  end

################################################################################

  def chef_server_client_destroy(name)
    (Chef::ApiClient.load(name).destroy rescue nil)
  end

################################################################################

  def load_role(role, role_path)
    ::Chef::Config[:role_path] = role_path
    role = ::Chef::Role.from_disk(role)
    role.save
    log("chef-server", "updated role: '#{role}'")
  end

################################################################################

  def create_databag(databag)
    @rest ||= Chef::REST.new(Chef::Config[:chef_server_url])
    @rest.post_rest("data", { "name" => databag })
  rescue Net::HTTPServerException => e
    raise unless e.to_s =~ /^409/
  end

  def load_databag_item(databag_item_path)
    ::Yajl::Parser.parse(IO.read(databag_item_path))
  end

  def load_databag(databag, databag_path)
    create_databag(databag)
    items = Dir.glob(File.expand_path(File.join(databag_path, "*.{json,rb}")))
    items.each do |item|
      next if File.directory?(item)

      item_path = File.basename(item)
      databag_item_path = File.expand_path(File.join(databag_path, item_path))

      data_bag_item = ::Chef::DataBagItem.new
      data_bag_item.data_bag(databag)
      data_bag_item.raw_data = load_databag_item(databag_item_path)
      data_bag_item.save
      log("chef-server", "updated data bag item: '#{databag}/#{item_path}'")
    end
  end

################################################################################

end

################################################################################
