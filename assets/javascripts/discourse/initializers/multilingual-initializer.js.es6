import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as discourseComputed } from "discourse-common/utils/decorators";
import { multilingualTagRenderer } from '../lib/multilingual';
import Composer from 'discourse/models/composer';
import { iconHTML } from "discourse-common/lib/icon-library";
import renderTag from "discourse/lib/render-tag";

export default {
  name: 'multilingual',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');
    if (!siteSettings.multilingual_enabled) return;
    
    Composer.serializeOnCreate('content_language_tags', 'contentLanguageTags');
    Composer.serializeToTopic('content_language_tags', 'topic.contentLanguageTags');
        
    I18n.translate_tag = function(tag) {
      let locale = I18n.currentLocale().split('_')[0];
      return I18n.lookup(`_tag.${tag}`, { locale }) || tag;
    }
            
    withPluginApi('0.8.36', api => {
      api.modifyClass('controller:preferences/interface', {
        @discourseComputed()
        availableLocales() {
          return this.site.interface_languages.map(l => {
            return {
              value: l.code,
              name: l.name
            }
          });
        },
        
        @discourseComputed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push('custom_fields');
          return attrs;
        },
        
        actions: {
          save() {
            // jQuery ajax removes empty arrays. This is a workaround
            let contentLanguages = this.model.custom_fields.content_languages;
            if (!contentLanguages || !contentLanguages.length) {
              this.set('model.custom_fields.content_languages', [""]);
            }
             
            return this._super().then(result => {
              const contentLanguages = this.site.content_languages;
              let rawUserLanguages = this.model.custom_fields.content_languages;
              let userLanguages = [];
              
              if (typeof rawUserLanguages === 'string') {
                rawUserLanguages = [rawUserLanguages];
              }
                            
              if (rawUserLanguages) {
                userLanguages = rawUserLanguages.map(code => {
                  return contentLanguages.find(cl => cl.code === code);
                });
              }
              
              // See workaround above
              userLanguages = userLanguages.filter(l => l !== "" && l !== undefined);
                              
              this.currentUser.set('content_languages', userLanguages);
            })
          }
        }
      });
      
      api.replaceTagRenderer(multilingualTagRenderer);
      
      api.modifyClass('component:bread-crumbs', {
        classNameBindings: ["category::no-category", ":category-breadcrumb"],
        
        @discourseComputed
        hidden() {}
      });
      
      api.modifyClass('component:tag-drop', {
        _prepareSearch(query) {
          const data = {
            q: query,
            filterForInput: true,
            limit: this.get("siteSettings.max_tag_search_results")
          };

          this.searchTags("/tags/filter/search", data, this._transformJson);
        }
      });
      
      api.addTagsHtmlCallback(function(topic, params) {
        const contentLanguageTags = topic.content_language_tags;
        if (!contentLanguageTags || !contentLanguageTags[0]) return;
        
        let html = '<div class="content-language-tags">';
        
        html += iconHTML('translate');
        
        contentLanguageTags.forEach(t => {
          html += renderTag(t, {
            contentLanguageTag: true,
            style: 'content-language-tag'
          }) + " ";
        });
        
        html += '</div>';
        
        return html;
      }, { priority: 100 });
    });
  }
}