import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import Controller from "@ember/controller";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse/lib/computed";
import AdminUser from "admin/models/admin-user";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Controller.extend({
  model: null,
  query: null,
  order: null,
  ascending: null,
  refreshing: false,
  listFilter: null,
  selectAll: false,
  searchHint: i18n("multilingual.languages.filter"),
  updateLabel: 'save',

  init() {
    this._super(...arguments);
    this._results = [];
    this._updatedLanguages = [];
    this.updatedLanguages = Ember.A();
    this.tagUpdateStarted = false;
  },

  @discourseComputed
  title() {
    return I18n.t("multilingual.languages.title");
  },

  _filterLanguages: discourseDebounce(function() {
    this.resetFilters();
  }, 250).observes("listFilter"),

  resetFilters() {
    this._results = [];
    this._refreshLanguages();
  },
  
  @discourseComputed('updatedLanguages.[]', 'updateLabel')
  updateLanguagesDisabled(updatedLanguages, updateLabel) {
    return updatedLanguages.length === 0 || updateLabel !== 'save';
  },
  
  _refreshLanguages() {
    this.set("refreshing", true);

    ajax('/admin/multilingual/languages', {
      data: {
        filter: this.listFilter,
        order: this.order,
        ascending: this.ascending
      }
    })
      .then(result => {
        this._results = this._results.concat(result);
        this.set("model", this._results);
      })
      .finally(() => this.set("refreshing", false));
  },
  
  actions: {
    uploadComplete() {
      this._refreshLanguages();
    },
  
    update() {
      if (this.updateLanguagesDisabled) {
        return;
      }
      
      this.set('updateLabel', 'saving');
            
      ajax('/admin/multilingual/languages', {
        method: "PUT",
        data: {
          languages: JSON.stringify(this.updatedLanguages)
        }
      })
        .then(result => {
          console.log(result);
          this.set('model', result);
          this.set('updateLabel', 'saved');
          setTimeout(() => {
            this.set('updateLabel', 'save');
          }, 4000);
        })
        .catch(popupAjaxError);
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
    }
  }
});
