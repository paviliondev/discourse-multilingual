export default {
  setupComponent(attrs, component) {
    let languages = component.get('currentUser.content_languages');
    let hasSet = languages.find(l => l && (l.code === 'set_content_language'));
    if (!hasSet) {
      languages = [...languages, {
        code: 'set_content_language',
        name: I18n.t('user.content_languages.set')
      }]
    }
    component.set('contentLanguages', languages);
  }
}