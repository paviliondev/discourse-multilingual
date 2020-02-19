import { on } from 'ember-addons/ember-computed-decorators';
import EmberObject from "@ember/object";

const paramName = "locale";

export default Ember.Component.extend({
  classNames: 'locale-selection',
  showHidden: false,

  @on('init')
  setup() {
    const availableLocales = this.availableLocales();    
    const currentLocale = I18n.currentLocale();
    
    let visibleList = this.siteSettings.multilingual_language_switcher_visible.split('|');
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
  
  removeParam() {
    let params = new URLSearchParams(window.location.search);
    console.log(params.toString())
    params.delete(paramName)
    let path = '/';
    params = params.toString();
    if (params.length) path += `?${params}`;
    if (window.location.hash.length) path += location.hash;
    window.history.replaceState(null, null, path);
  },
  
  addParam(locale) {
    $.cookie(`discourse_${paramName}`, locale);
    let params = new URLSearchParams(window.location.search);
    params.set(paramName, locale);
    window.location.search = params;
  },
  
  availableLocales() {
    return this.site.interface_languages.map(l => {
      return EmberObject.create(Object.assign({}, l, { class: "locale" }));
    });
  },

  didInsertElement() {
    this.removeParam();
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
      this.addParam(locale);
    },

    showHidden() {
      this.toggleProperty('showHidden');
    }
  }
});
