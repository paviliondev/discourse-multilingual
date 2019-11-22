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


