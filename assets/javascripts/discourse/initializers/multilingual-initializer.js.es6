import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default {
  name: 'multilingual',
  initialize(container) {
    withPluginApi('0.8.23', api => {
      api.modifyClass('route:preferences-interface', {
        afterModel(model) {
          return ajax('/multilingual/languages').then(result => {
            model.set('contentLanguages', result);
          })
        }
      });
      
      api.modifyClass('controller:preferences/interface', {
        @computed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push('custom_fields');
          return attrs;
        },
        
        actions: {
          save() {
            return this._super().then(result => {
              const contentLanguages = this.model.contentLanguages;
              const userContentLanguages = this.model.custom_fields.content_languages;
              
              Discourse.User.current().setProperties({
                content_languages: userContentLanguages.map(code => {
                  return contentLanguages.find(cl => cl.code === code);
                })
              });
            })
          }
        }
      });
    });
  }
}