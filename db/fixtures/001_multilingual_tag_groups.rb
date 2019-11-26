tag_group = TagGroup.find_by(name: 'languages')

if tag_group.blank?
  tag_group = TagGroup.new(
    name: 'languages',
    permissions: {
      everyone: 1
    }
  )

  tag_group.save
else
  tag_group.permissions = { everyone: 1 }
  tag_group.save
end


