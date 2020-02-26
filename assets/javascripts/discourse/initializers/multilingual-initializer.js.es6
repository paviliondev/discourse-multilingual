import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as discourseComputed, observes, on } from "discourse-common/utils/decorators";
import { multilingualTagRenderer } from '../lib/multilingual-tag';
import { multilingualCategoryLinkRenderer } from '../lib/multilingual-category';
import { discoveryParams, localeParam, removeParam } from '../lib/multilingual-route';
import { isContentLanguage } from '../lib/multilingual';
import Composer from 'discourse/models/composer';
import { iconHTML } from "discourse-common/lib/icon-library";
import renderTag from "discourse/lib/render-tag";
import { notEmpty } from "@ember/object/computed";

export default {
  name: 'multilingual',
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    
    if (!siteSettings.multilingual_enabled) return;
    
    if (siteSettings.multilingual_content_languages_enabled) {
      Composer.serializeOnCreate('content_language_tags', 'contentLanguageTags');
      Composer.serializeToTopic('contentLanguageTags', 'topic.content_language_tags');
    }
            
    I18n.translate_tag = function(tag) {
      const translations = I18n.tag_translations || {};
      return translations[tag] || tag;
    }
            
    withPluginApi('0.8.36', api => {
      api.replaceTagRenderer(multilingualTagRenderer);
      api.replaceCategoryLinkRenderer(multilingualCategoryLinkRenderer);
      
      discoveryParams.forEach(param => {
        api.addDiscoveryQueryParam(param, {
          replace: true,
          refreshModel: true 
        });
      });
      
      api.onPageChange(() => removeParam(localeParam, { ctx: this }));
      
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
            if (!siteSettings.multilingual_content_languages_enabled) {
              return this._super();
            }
            
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
              userLanguages = userLanguages.filter(l => l && isContentLanguage(l.code));
                              
              currentUser.set('content_languages', userLanguages);
            })
          }
        }
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
        
        if (!siteSettings.multilingual_content_languages_enabled ||
          (!contentLanguageTags || !contentLanguageTags[0])) return;
        
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
      
      if (!currentUser && siteSettings.multilingual_guest_language_switcher === "header") {
        api.reopenWidget('header', {
          defaultState() {
            return jQuery.extend(this._super(...arguments), { languageSwitcherMenuVisible: false });
          },
          
          toggleLangugeSwitcherMenu() {
            this.state.languageSwitcherMenuVisible = !this.state.languageSwitcherMenuVisible;
          }
        });
        
        api.decorateWidget('header-icons:before', helper => {
          return helper.attach('header-dropdown', {
            title: "user.locale.title",
            icon: "translate",
            iconId: "language-switcher-menu-button",
            action: "toggleLangugeSwitcherMenu",
            active: helper.widget.parentWidget.state.languageSwitcherMenuVisible
          });
        });
        
        api.addHeaderPanel('language-switcher-menu', 'languageSwitcherMenuVisible', (attrs, state) => ({ attrs, state }));
      }
      
      api.modifyClass('route:tag-groups-edit', {        
        setupController(controller, model) {
          this._super(controller, model);
          
          if (model.content_language_group) {
            controller.setupContentTagControls();
          }
        },
        
        actions: {
          tagsChanged() {
            this.refresh();
          }
        }
      });
      
      api.modifyClass('controller:tag-groups-edit', {
        setupContentTagControls() {
          Ember.run.scheduleOnce('afterRender', () => {
            $(".tag-groups-container").addClass('content-tags');
            $(".tag-group-content h1 input").prop('disabled', true);
            $(".content-tag-controls").appendTo('.tag-group-content');
          });
        }
      });
      
      api.modifyClass('component:admin-directory-toggle', {
        showToggle: notEmpty('toggleAll'),
        
        click(e) {
          if ($(e.target).parents('.toggle-all').length) {
            return true;
          } else {
            return this._super(e);
          }
        },
      });
    });
  }
}