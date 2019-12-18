import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import Controller from "@ember/controller";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse/lib/computed";
import AdminUser from "admin/models/admin-user";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import MultilingualLanguage from '../models/multilingual-language';

export default Controller.extend({
  queryParams: ['filter', 'ascending', 'order'],
  refreshing: false,
  filterHint: i18n("multilingual.languages.filter"),
  updateState: 'save',
  updatedLanguages: Ember.A(),

  @discourseComputed
  title() {
    return I18n.t("multilingual.languages.title");
  },
  
  setupObservers() {
    this.addObserver('filter', this._filterLanguages);
    this.addObserver('ascending', this._filterLanguages);
    this.addObserver('order', this._filterLanguages);
  },
  
  _filterLanguages: discourseDebounce(function() {
    this._refreshLanguages();
  }, 250),
  
  @discourseComputed('updatedLanguages.[]', 'updateState')
  updateLanguagesDisabled(updatedLanguages, updateState) {
    return updatedLanguages.length === 0 || updateState !== 'save';
  },
  
  _updateLanguages(languages) {
    this.setProperties({
      updatedLanguages: Ember.A(),
      languages
    });
  },
  
  _refreshLanguages() {
    this.set("refreshing", true);
    
    let params = {};
    ['filter', 'ascending', 'order'].forEach(p => {
      let val = this.get(p);
      if (val) params[p] = val;
    });
    
    MultilingualLanguage.all(params).then(result => {
      this._updateLanguages(result);
    }).finally(() => {
      this.set("refreshing", false)
    });
  },
  
  actions: {
    languagesChanged() {
      this._refreshLanguages();
    },
  
    update() {
      if (this.updateLanguagesDisabled) return;
      
      this.set('updateState', 'saving');
      
      MultilingualLanguage.save(this.updatedLanguages)
        .then(results => {
          this._updateLanguages(result);
          this.set('updateState', 'saved');
          setTimeout(() => {
            this.set('updateState', 'save');
          }, 4000);
        });
    },

    updateLanguages(languages) {
      this._updateLanguages(languages);
    }
  }
});
