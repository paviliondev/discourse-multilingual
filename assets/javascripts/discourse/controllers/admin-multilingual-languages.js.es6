import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import Controller from "@ember/controller";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse/lib/computed";
import AdminUser from "admin/models/admin-user";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import MultilingualLanguage from '../models/multilingual-language';
import { notEmpty } from "@ember/object/computed";
import { A } from "@ember/array";

export default Controller.extend({
  refreshing: false,
  queryPlaceholder: i18n("multilingual.languages.query_placeholder"),
  updateState: 'save',
  languages: [],
  updatedLanguages: A(),
  anyLanguages: notEmpty('filteredLanguages'),

  @discourseComputed
  title() {
    return I18n.t("multilingual.languages.title");
  },
  
  setupObservers() {
    this.addObserver('query', this._filterLanguages);
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
  
  @discourseComputed('languages.[]', 'customOnly')
  filteredLanguages(languages, customOnly) {
    if (customOnly) return languages.filter(l => l.custom);
    return languages;
  },
  
  _updateLanguages(languages) {
    this.setProperties({
      updatedLanguages: A(),
      languages
    });
  },
  
  _refreshLanguages() {
    this.set("refreshing", true);
    
    let params = {};
    ['query', 'ascending', 'order'].forEach(p => {
      let val = this.get(p);
      if (val) params[p] = val;
    });
            
    MultilingualLanguage.list(params).then(result => {
      this._updateLanguages(result);
    }).finally(() => {
      this.set("refreshing", false)
    });
  },
  
  actions: {
    refreshLanguages() {
      this._refreshLanguages();
    },
  
    update() {
      if (this.updateLanguagesDisabled) return;
      
      this.set('updateState', 'saving');
      
      MultilingualLanguage.save(this.updatedLanguages)
        .then(result => {
          this._updateLanguages(result);
          this.set('updateState', 'saved');
          setTimeout(() => { this.set('updateState', 'save') }, 4000);
        });
    },

    updateLanguages(languages) {
      this._updateLanguages(languages);
    },
    
    languagesUploaded() {
      this.set('customOnly', true);
      this._refreshLanguages();
    }
  }
});
