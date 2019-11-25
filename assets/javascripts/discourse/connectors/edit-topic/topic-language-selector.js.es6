import { languageTags, languageTag, addLanguageTags } from '../../lib/multilingual';

export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
    
    attrs.buffered.addObserver('language_tags', () => {
      if (this._state === 'destroying') return;
      addLanguageTags(attrs.buffered, attrs.buffered.get('language_tags'));
    });
  }
}