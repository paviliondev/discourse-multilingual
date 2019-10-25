tag_group = TagGroup.find_by(name: 'languages')

if tag_group.blank?
  tag_group = TagGroup.new(
    name: 'languages',
    permissions: {
      staff: 1
    }
  )

  tag_group.save
end

languages = YAML.safe_load(File.read(File.join(
  Rails.root,
  'plugins',
  'discourse-multilingual',
  'config',
  'languages.yml'
)))

if languages.present? && languages["languages"].any?
  languages["languages"].keys.each do |code|
    tag = Tag.find_by(name: code)

    if tag.blank?
      tag = Tag.new(name: code)
      tag.save
    end
    
    group_membership = TagGroupMembership.new(
      tag_id: tag.id,
      tag_group_id: tag_group.id
    )
    group_membership.save    
  end
end


