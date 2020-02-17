import { on } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'locale-selection',
  showHidden: false,

  @on('init')
  setup() {
    const localeValues = this.siteSettings.multilingual_language_switcher_visible.split('|');
    const availableLocales = JSON.parse(this.siteSettings.available_locales);
    let visibleLocales = [];
    let hiddenLocales = [];

    availableLocales.forEach((l) => {
      if (localeValues.indexOf(l.value) > -1) {
        visibleLocales.push(l);
      } else {
        hiddenLocales.push(l);
      }
    });
    
    this.setProperties({ visibleLocales, hiddenLocales });
  },

  didInsertElement() {
    this.set('clickOutsideHandler', Ember.run.bind(this, this.clickOutside));
    Ember.$(document).on('click', this.get('clickOutsideHandler'));
  },

  willDestroyElement() {
    Ember.$(document).off('click', this.get('clickOutsideHandler'));
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
      $.cookie('discourse_guest_locale', locale);
      window.location.reload();
    },

    showHidden() {
      this.toggleProperty('showHidden');
    }
  }
});
