class Multilingual::AdminController < Admin::AdminController
  def index
    render_json_dump(
      content_language_tag_group_id: Multilingual::ContentTag.group.id
    ) 
  end
end