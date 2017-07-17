module ActiveRecord
  class Base
    class << self
      # Undefines private Kernel#open method to allow using `open` scopes in models.
      undef open

      # Defines convenience methods for a timesteamp. E.g.:
      # timestamp_methods :closed_at, set: :close!, unset: :open!, ask: :closed?
      # 
      # def close!
      #   update_attribute :closed_at, DateTime.now
      # end

      # def open!
      #   update_attribute :closed_at, nil
      # end

      # def closed?
      #   !!self.closed_at
      # end
      def timestamp_methods(field, methods)
        define_method methods[:set] {update_attribute field, DateTime.now} if methods[:set]
        define_method methods[:unset] {update_attribute field, nil} if methods[:unset]
        define_method methods[:ask] {!!self.send(field)} if methods[:ask]
      end

      def find_or_initialize_many(hashes, attributes, property=nil)
        attributes = [attributes] unless attributes.is_a? Array
        hashes.each do |hash|
          resource = self.find_or_initialize_by(hash.slice(*attributes))
          resource.attributes = hash
          resource.property = property if property

          resource.save!
          resource
        end
      end
    end
  end
end
