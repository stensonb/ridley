module Ridley
  class EnvironmentObject < Ridley::ChefObject
    set_chef_id "name"
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"

    attribute :name,
      required: true

    attribute :description,
      default: String.new

    attribute :default_attributes,
      default: Hashie::Mash.new

    attribute :override_attributes,
      default: Hashie::Mash.new

    attribute :cookbook_versions,
      default: Hashie::Mash.new

    class << self

      # EnvironmentObject 'factory' from a json file
      def from_file(file)
        from_json(File.read(file))
      end

      # EnvironmentObject 'factory' from a json string
      def from_json(str)

        # parse to hash
        parsed = JSON.parse(str)

        # build and fill return object
        obj = self.new(???) # <-- how to I call this constructor?
        obj.name = parsed["name"]
        obj.description = parsed["description"]
        obj.default_attributes = Hashie::Mash.new parsed["default_attributes"]
        obj.override_attributes = Hashie::Mash.new parsed["override_attributes"]
        obj.cookbook_versions = Hashie::Mash.new parsed["cookbook_versions"]

        obj
      end
    end

    # Set an environment level default attribute given the dotted path representation of
    # the Chef attribute and value
    #
    # @example setting and saving an environment level default attribute
    #
    #   obj = environment.find("production")
    #   obj.set_default_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [Hashie::Mash]
    def set_default_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
      self.default_attributes = self.default_attributes.deep_merge(attr_hash)
    end

    # Set an environment level override attribute given the dotted path representation of
    # the Chef attribute and value
    #
    # @example setting and saving an environment level override attribute
    #
    #   obj = environment.find("production")
    #   obj.set_override_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [Hashie::Mash]
    def set_override_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
      self.override_attributes = self.override_attributes.deep_merge(attr_hash)
    end
  end
end
