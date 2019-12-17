import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import Controller from "@ember/controller";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse/lib/computed";
import AdminUser from "admin/models/admin-user";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import MultilingualLanguage from '../models/multilingual-language';

export default Controller.extend({
  model: null,
  query: null,
  order: null,
  ascending: null,
  refreshing: false,
  filter: null,
  selectAll: false,
  searchHint: i18n("multilingual.languages.filter"),
  updateLabel: 'save',

  init() {
    this._super(...arguments);
    this._updatedLanguages = [];
    this.updatedLanguages = Ember.A();
    this.tagUpdateStarted = false;
  },

  @discourseComputed
  title() {
    return I18n.t("multilingual.languages.title");
  },

  _filterLanguages: discourseDebounce(function() {
    this._refreshLanguages();
  }, 250).observes("filter", "ascending", "order"),
  
  @discourseComputed('updatedLanguages.[]', 'updateLabel')
  updateLanguagesDisabled(updatedLanguages, updateLabel) {
    return updatedLanguages.length === 0 || updateLabel !== 'save';
  },
  
  _refreshLanguages() {
    this.set("refreshing", true);
    
    let params = {};
    ['filter', 'ascending', 'order'].forEach(p => {
      let val = this.get(p);
      if (val) params[p] = val;
    });
    
    MultilingualLanguage.all(params).then(result => {
      this.set("model", result);
    }).finally(() => this.set("refreshing", false));
  },
  
  actions: {
    languagesChanged() {
      this._refreshLanguages();
    },
  
    update() {
      if (this.updateLanguagesDisabled) {
        return;
      }
      
      this.set('updateLabel', 'saving');
      
      MultilingualLanguage.save(this.updatedLanguages)
        .then(result => {
          this.set('model', result);
          this.set('updateLabel', 'saved');
          setTimeout(() => {
            this.set('updateLabel', 'save');
          }, 4000);
        });
    },
    
    updateTags() {
      ajax('/admin/multilingual/languages/tags', {
        type: 'PUT'
      })
        .then(result => {
          if (result.success) {
            this.set('actionMessage', 'multilingual.languages.update_tags_started');
            setTimeout(() => {
              this.set('actionMessage', null);
            }, 10000);
          }
        });
    },
    
    updateModel(languages) {
      this.set('model', languages);
    }
  }
});
