import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import {
  default as discourseComputed,
  on,
  observes
} from "discourse-common/utils/decorators";
import {
  contentLanguageTag,
  contentLanguageTagsFilter,
  multilingualTagRenderer,
  userContentLanguageCodes
} from '../lib/multilingual';
import Composer from 'discourse/models/composer';
import { iconHTML } from "discourse-common/lib/icon-library";
import renderTag from "discourse/lib/render-tag";

export default {
  name: 'multilingual',
  initialize(container) {
    const site = container.lookup('site:main');
    const currentUser = container.lookup('current-user:main');
    const siteSettings = container.lookup('site-settings:main');
    
    if (!siteSettings.multilingual_enabled) return;
    
    Composer.serializeOnCreate('languages');
    Composer.serializeToTopic('languages', 'topic.languages');
    
    I18n.translate_tag = function(tag) {
      return I18n.translate(`_tag.${tag}`) || tag;
    }
            
    withPluginApi('0.8.36', api => {
      api.modifyClass('controller:preferences/interface', {
        @discourseComputed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push('custom_fields');
          return attrs;
        },
        
        actions: {
          save() {
            return this._super().then(result => {
              const contentLanguages = this.site.content_languages;
              const rawUserLanguages = this.model.custom_fields.content_languages;
              let userLanguages = [];
              
              if (rawUserLanguages && rawUserLanguages[0] !== 'none') {
                userLanguages = rawUserLanguages.map(code => {
                  return contentLanguages.find(cl => cl.code === code);
                });
              }
                
              currentUser.set('content_languages', userLanguages);
            })
          }
        }
      });
      
      api.replaceTagRenderer(multilingualTagRenderer);
      
      api.modifyClass('component:mini-tag-chooser', {
        willComputeAsyncContent(content) {
          return contentLanguageTagsFilter(content, 'name', 'name', 'willComputeAsyncContent');
        },

        @discourseComputed("tags")
        selection(tags) {
          return contentLanguageTagsFilter(this._super(tags), 'value', 'value', 'selection');
        },
        
        @discourseComputed("tags.[]", "filter", "highlightedSelection.[]")
        collectionHeader(tags, filter, highlightedSelection) {
          let html = this._super(...arguments);
          let $html = $(html);
          
          $html.find('button').each(function() {
            let tag = $(this).data('value');
            if (contentLanguageTag(tag)) {
              $(this).remove();
              return;
            }
            let translatedTag = I18n.translate_tag(tag);
            $(this).attr({
              'aria-label': translatedTag,
              "title": translatedTag
            });
            $(this).html(`${translatedTag} ${iconHTML("times")}`)
          });
          
          return $html.html();
        }
      });
      
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
        
        let html = '<div class="topic-languages">';
        html += iconHTML('translate');
        contentLanguageTags.forEach(t => {
          html += renderTag(t, { language: true }) + " ";
        });
        html += '</div>';
        return html;
      }, { priority: 100  });
      
      api.modifyClass('controller:composer', {
        _setModel(composerModel, opts) {
          if (opts.draftKey === 'new_topic') {
            let userTags = userContentLanguageCodes();
            if (userTags) {
              opts.topicTags = (opts.topicTags || []).concat(userTags);
            }  
          }
          this._super(composerModel, opts);
        }
      })
    });
  }
}