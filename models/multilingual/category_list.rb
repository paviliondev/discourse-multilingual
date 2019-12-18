### Note ###
# The featured topic list in CategoryList is used in the /categories route:
#   * when desktop_category_page_style includes 'featured'; and / or
#   * on mobile
# It does not use TopicQuery and does not have access to the current_user.
# The approach below ensures non-content-language topics do not appear, but
# as it is filtering a limited list of 100 featured topics, may be empty when
# relevant topics in the user's content-language remain in the category.
###

module Multilingual::CategoryList
  def trim_results
    @categories.each do |c|
      next if c.displayable_topics.blank?
      c.displayable_topics = c.displayable_topics.select do |topic|
        Multilingual::Tag.filter(topic).any?
      end
    end
    super
  end
end

class ::CategoryList
  prepend Multilingual::CategoryList
end