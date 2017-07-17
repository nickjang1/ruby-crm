module Ransack
  module Helpers
    module FormHelper
      private
      def order_indicator_for(order)
        if order == 'asc'
          '&#8593;'
        elsif order == 'desc'
          '&#8595;'
        else
          nil
        end
      end
    end
  end
end