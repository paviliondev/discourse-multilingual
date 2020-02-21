import { on } from 'ember-addons/ember-computed-decorators';
import EmberObject from "@ember/object";
import { addParam, localeParam } from '../lib/multilingual-route';

export default Ember.Component.extend({
  classNames: 'locale-selection',
  showHidden: false,

  @on('init')
  setup() {
    const availableLocales = this.availableLocales();    
    const currentLocale = I18n.currentLocale();
    
    let visibleList = this.siteSettings.multilingual_locale_switcher_footer_visible.split('|');
    let visibleLocales = [];
    let hiddenLocales = [];

    availableLocales.forEach((l) => {
      if (l.code === currentLocale) {
        l.set('class', `${l.class} current`);
        
        if (visibleList.indexOf(l.code) === -1) {
          visibleList.pop();
          visibleList.push(l.code);
        }
      }
      
      if (visibleList.indexOf(l.code) > -1) {
        visibleLocales.push(l);
      } else {
        hiddenLocales.push(l);
      }
    });
        
    this.setProperties({ visibleLocales, hiddenLocales });
  },
  
  availableLocales() {
    return this.site.interface_languages.map(l => {
      return EmberObject.create(Object.assign({}, l, { class: "locale" }));
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
    const $hidden = this.$('.hiddenLocales');
    const $target = $(e.target);
    
    if (!$target.closest($hidden).length) {
      this.set("showHidden", false);
    }
  },

  actions: {
    changeLocale(locale) {
      this.set('showHidden', false);
      addParam(localeParam, locale, { add_cookie: true, ctx: this });
    },

    showHidden() {
      this.toggleProperty('showHidden');
    }
  }
});
