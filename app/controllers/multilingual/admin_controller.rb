# frozen_string_literal: true
class Multilingual::AdminController < Admin::AdminController
  requires_plugin Multilingual::PLUGIN_NAME

  def index
    render_json_dump(content_language_tag_group_id: Multilingual::ContentTag.enabled_group.id)
  end
end
