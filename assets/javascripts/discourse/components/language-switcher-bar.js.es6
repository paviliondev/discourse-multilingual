import { on } from 'ember-addons/ember-computed-decorators';
import EmberObject from "@ember/object";
import { addParam, localeParam } from '../lib/multilingual-route';
import { notEmpty } from "@ember/object/computed";

export default Ember.Component.extend({
  classNames: 'language-switcher-bar',
  showHidden: false,
  showHiddenToggle: notEmpty('hiddenLanguages'),

  @on('init')
  setup() {
    const availableLanguages = this.availableLanguages();    
    const currentLanguage = I18n.currentLocale();
    let visibleList = this.siteSettings.multilingual_guest_language_switcher_footer_visible.split('|');
    
    availableLanguages.forEach((l) => {
      if (l.code === currentLanguage) {
        l.set('class', `${l.class} current`);
        
        if (visibleList.indexOf(l.code) === -1) {
          visibleList.pop();
          visibleList.unshift(l.code);
        }
      }
    });
    
    const visibleLimit = this.site.mobileView ? 3 : 10;
    let visibleLanguages = [];
    let hiddenLanguages = [];
    availableLanguages.forEach((l) => {
      if (visibleList.indexOf(l.code) > -1 && visibleLanguages.length < visibleLimit) {
        visibleLanguages.push(l);
      } else {
        hiddenLanguages.push(l);
      }
    })
    
    this.setProperties({ visibleLanguages, hiddenLanguages });
  },
  
  availableLanguages() {
    return this.site.interface_languages.map(l => {
      return EmberObject.create(Object.assign({}, l, { class: "language" }));
    });
  },

  didInsertElement() {
    this.set('clickOutsideHandler', Ember.run.bind(this, this.clickOutside));
    $(document).on('click', this.clickOutsideHandler);
  },

  willDestroyElement() {
    $(document).off('click', this.clickOutsideHandler);
  },

  clickOutside(e) {
    const $hidden = $('.language-switcher-bar .hidden-languages');
    const $target = $(e.target);
    
    if (!$target.closest($hidden).length) {
      this.set("showHidden", false);
    }
  },

  actions: {
    change(code) {
      this.set('showHidden', false);
      addParam(localeParam, code, { add_cookie: true, ctx: this });
    },

    toggleHidden() {
      this.toggleProperty('showHidden');
    }
  }
});
