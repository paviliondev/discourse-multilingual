import {
  default as discourseComputed,
  observes,
} from "discourse-common/utils/decorators";
import MultilingualLanguage from "../models/multilingual-language";
import Component from "@ember/component";
import { deepEqual } from "discourse-common/lib/object";

export default Component.extend({
  tagName: "tr",
  classNames: "language",

  didInsertElement() {
    this.currentLanguage = JSON.parse(JSON.stringify(this.language));
  },

  @observes("language.content_enabled", "language.interface_enabled")
  trackUpdates() {
    if (deepEqual(this.currentLanguage, this.language)) {
      this.updatedLanguages.removeObject(this.language);
    } else {
      this.updatedLanguages.addObject(this.language);
    }
  },

  @discourseComputed("language.custom")
  typeKey(custom) {
    return `multilingual.languages.${custom ? "custom" : "base"}`;
  },

  @discourseComputed("language.locale")
  interfaceToggleDisabled(locale) {
    return locale === "en";
  },

  @discourseComputed("language.content_tag_conflict")
  contentDisabled(tagConflict) {
    return (
      !this.siteSettings.multilingual_content_languages_enabled || tagConflict
    );
  },

  @discourseComputed
  interfaceDisabled() {
    return !this.siteSettings.allow_user_locale;
  },

  @discourseComputed("language.custom")
  actionsDisabled(custom) {
    return !custom;
  },

  @discourseComputed
  contentClass() {
    return this.generateControlColumnClass("content");
  },

  @discourseComputed
  interfaceClass() {
    return this.generateControlColumnClass("interface");
  },

  @discourseComputed
  actionsClass() {
    return this.generateControlColumnClass("actions");
  },

  generateControlColumnClass(type) {
    let columnClass = `language-control ${type}`;
    if (this.get(`${type}Disabled`)) {
      columnClass += " disabled";
    }
    return columnClass;
  },

  actions: {
    remove() {
      this.set("removing", true);
      let locales = [this.get("language.locale")];
      MultilingualLanguage.remove(locales).then((result) => {
        this.set("removing", false);
        this.removed(result);
      });
    },
  },
});
