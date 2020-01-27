import { contentLanguageTags, contentLanguageTag, addContentLanguageTags } from '../../lib/multilingual';

export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
    
    attrs.buffered.addObserver('content_language_tags', () => {
      if (this._state === 'destroying') return;
      addContentLanguageTags(attrs.buffered, attrs.buffered.get('content_language_tags'));
    });
  }
}