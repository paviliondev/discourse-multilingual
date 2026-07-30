/* eslint-disable ember/no-observers */

import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { debounce } from "@ember/runloop";
import discourseDebounce from "discourse/lib/debounce";
import { autoTrackedArray } from "discourse/lib/tracked-tools";
import { i18n } from "discourse-i18n";
import MultilingualLanguage from "../models/multilingual-language";

export default class AdminMultilingualLanguagesController extends Controller {
  @tracked refreshing = false;
  @tracked customOnly = false;
  @tracked updateState = "save";
  @autoTrackedArray languages = [];
  @autoTrackedArray updatedLanguages = [];

  queryPlaceholder = i18n("multilingual.languages.query_placeholder");

  get title() {
    return i18n("multilingual.languages.title");
  }

  setupObservers() {
    this.addObserver("query", this._filterLanguages);
    this.addObserver("ascending", this._filterLanguages);
    this.addObserver("order", this._filterLanguages);
  }

  _filterLanguages() {
    // TODO: Use discouseDebounce when discourse 2.7 gets released.
    const debounceFunc = discourseDebounce || debounce;

    debounceFunc(this, this._refreshLanguages, 250);
  }

  get updateLanguagesDisabled() {
    return this.updatedLanguages.length === 0 || this.updateState !== "save";
  }

  get filteredLanguages() {
    if (this.customOnly) {
      return this.languages.filter((l) => l.custom);
    }
    return this.languages;
  }

  get anyLanguages() {
    return this.filteredLanguages.length > 0;
  }

  _updateLanguages(languages) {
    this.updatedLanguages = [];
    this.languages = languages;
  }

  _refreshLanguages() {
    this.refreshing = true;

    const params = {};
    ["query", "ascending", "order"].forEach((p) => {
      const val = this.get(p);
      if (val) {
        params[p] = val;
      }
    });

    MultilingualLanguage.list(params)
      .then((result) => {
        this._updateLanguages(result);
      })
      .finally(() => {
        this.refreshing = false;
      });
  }

  @action
  refreshLanguages() {
    this._refreshLanguages();
  }

  @action
  update() {
    if (this.updateLanguagesDisabled) {
      return;
    }

    this.updateState = "saving";

    MultilingualLanguage.save(this.updatedLanguages).then((result) => {
      this._updateLanguages(result);
      this.updateState = "saved";
      setTimeout(() => {
        this.updateState = "save";
      }, 4000);
    });
  }

  @action
  updateLanguages(languages) {
    this._updateLanguages(languages);
  }

  @action
  languagesUploaded() {
    this.customOnly = true;
    this._refreshLanguages();
  }
}
