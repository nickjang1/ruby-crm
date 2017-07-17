# == Schema Information
#
# Table name: tags
#
#  id                :integer          not null, primary key
#  type              :string(255)
#  name              :string(255)
#  unboxed_countable :boolean
#  parent_id         :integer
#  position          :integer
#  created_at        :datetime
#  updated_at        :datetime
#  property_id       :integer
#

class Tag < ActiveRecord::Base
  attr_accessor :operation, :other_id

  TYPES = %w(Category Location List)
  OPERATIONS = %w(nest_under move_above move_below)
  INVALID_TAG_OPERATION = 'is not a valid tag for this operation'

  include RankedModel
  ranks :siblings, column: :position, with_same: :parent_id

  acts_as_tree order: :position, dependent: :destroy

  # validate :validate_has_items
  # validate :validate_items_do_not_belong_to_other_tags

  validates :name, presence: true
  validates :operation, 
    presence: {message: 'must specify an operation'}, 
    inclusion: {in: OPERATIONS, message: 'is not a valid operation'},
    if: :operation_or_other_id?
  validates :other_id,  
    presence: true,
    numericality: true,
    inclusion: {in: proc {|tag| tag.class.where{id != tag.id}.map{|tag| tag.id}}, message: INVALID_TAG_OPERATION},
    if: :operation_or_other_id?
  
  around_save :rearrange, if: :operation_or_other_id?

  belongs_to :property
  belongs_to :user
  has_many :item_tags, dependent: :destroy
  has_many :items, through: :item_tags

  scope :categories, -> { where(type: TYPES[0]) }
  scope :locations, -> { where(type: TYPES[1]) }
  scope :lists, -> { where(type: TYPES[2]) }

  # scope :for_property, ->(property){ where(property_id: property) }
  default_scope { where(property_id: Property.current_id) }

  class << self
    def selves_and_descendants
      unscoped.where id: all.map{|tag| Tag.unscoped {tag.self_and_descendants.pluck(:id)}}.flatten.uniq
    end

    # Removes type from 'attributes_protected_by_default'
    def attributes_protected_by_default
      ['id']
    end

    def types
      TYPES
    end

    def operations
      OPERATIONS
    end

    def autocomplete_source(type = 'scoped')
      Tag.roots_and_descendants_preordered.send(type).map do |t|
        {
          id: t.id,
          value: t.name,
          depth: t.depth,
          search: t.self_and_ancestors.send(type).map(&:name).reverse.concat(t.descendants.send(type).map(&:name)).join(' ')
        }
      end.to_json
    end
  end

  def other_id=(val)
    @other_id = val.to_i unless val.blank?
  end

  def operation_or_other_id?
    operation.present? || other_id.present?
  end
  
  def plain_text_node
    (self.depth.times.map{'&nbsp;' * 2}.join + self.name).html_safe
  end

  def update_items(params)
    params[:tag][:add] && params[:tag][:add][:item_ids].each do |item_id|
      self.items << Item.find(item_id) unless self.items.exists?(item_id)
    end
    params[:tag][:remove] && params[:tag][:remove][:item_ids].each do |item_id|
      self.items.delete(Item.find(item_id)) unless !self.items.exists?(item_id)
    end
    
    true
  end

  # Based on
  # https://github.com/mixonic/ranked-model/issues/10
  # Replace with solution provided in (when closed)
  # https://github.com/mixonic/ranked-model/issues/33
  def calculated_siblings_position
    self.self_and_siblings.where('position < ?', self.position).count
  end

  def to_s
    self.name
  end

  # around_save, save happens at `yield`, but it can be aborted raising a ActiveRecord::Rollback
  def rearrange
    yield
    other = Tag.where(id: self.other_id).first
    operation = self.operation
    self.operation = self.other_id = nil

    begin
      case operation
        when 'nest_under'
          self.update_attribute :parent_id, other.id
          self.update_attribute :siblings_position, 0
          raise 'Cyclic nesting!' if other.parent_id == id
        when 'move_above'
          self.update_attribute :parent_id, other.parent_id
          self.update_attribute :siblings_position, other.calculated_siblings_position - 1
        when 'move_below'
          self.update_attribute :parent_id, other.parent_id
          self.update_attribute :siblings_position, other.calculated_siblings_position + 1
      end
    rescue
      self.errors.add :other_id, INVALID_TAG_OPERATION
      raise ActiveRecord::Rollback
    end
  end


  private

  def other_tags_of_same_type
    self.class.where.not(id: self)
  end

  # ensures that items do not belongs to other tags of the same type
  def validate_items_do_not_belong_to_other_tags
    other_occurences = other_tags_of_same_type.
      joins(:item_tags).
      where(item_tags: {item_id: self.items.map(&:id)}).count

    if other_occurences > 0
      self.errors.add(:base, "can not contain items that "\
                             "belong to another #{self.class.to_s.downcase}")
    end
  end

  def validate_has_items
    if self.items.blank?
      errors.add(:base, 'must contain at least one item!')
    end
  end
end
