/* eslint-disable ember/no-classic-components, ember/require-tagless-components */

import Component from "@ember/component";
import { action, computed } from "@ember/object";
import { classNames, tagName } from "@ember-decorators/component";
import { observes } from "discourse/lib/decorators";
import { deepEqual } from "discourse/lib/object";
import MultilingualLanguage from "../models/multilingual-language";

@tagName("tr")
@classNames("language")
export default class AdminLanguage extends Component {
  didInsertElement() {
    super.didInsertElement(...arguments);
    this.currentLanguage = JSON.parse(JSON.stringify(this.language));
  }

  @observes("language.content_enabled", "language.interface_enabled")
  trackUpdates() {
    if (deepEqual(this.currentLanguage, this.language)) {
      const index = this.updatedLanguages.indexOf(this.language);
      if (index !== -1) {
        this.updatedLanguages.splice(index, 1);
      }
    } else if (!this.updatedLanguages.includes(this.language)) {
      this.updatedLanguages.push(this.language);
    }
  }

  @computed("language.custom")
  get typeKey() {
    return `multilingual.languages.${
      this.language.custom ? "custom" : "base"
    }`;
  }

  @computed("language.locale")
  get interfaceToggleDisabled() {
    return this.language.locale === "en";
  }

  @computed(
    "language.content_tag_conflict",
    "siteSettings.multilingual_content_languages_enabled"
  )
  get contentDisabled() {
    return (
      !this.siteSettings.multilingual_content_languages_enabled ||
      this.language.content_tag_conflict
    );
  }

  @computed("siteSettings.allow_user_locale")
  get interfaceDisabled() {
    return !this.siteSettings.allow_user_locale;
  }

  @computed("language.custom")
  get actionsDisabled() {
    return !this.language.custom;
  }

  @computed("contentDisabled")
  get contentClass() {
    return this.generateControlColumnClass("content");
  }

  @computed("interfaceDisabled")
  get interfaceClass() {
    return this.generateControlColumnClass("interface");
  }

  @computed("actionsDisabled")
  get actionsClass() {
    return this.generateControlColumnClass("actions");
  }

  generateControlColumnClass(type) {
    let columnClass = `language-control ${type}`;
    if (this.get(`${type}Disabled`)) {
      columnClass += " disabled";
    }
    return columnClass;
  }

  @action
  remove() {
    this.set("removing", true);
    const locales = [this.get("language.locale")];
    MultilingualLanguage.remove(locales).then((result) => {
      this.set("removing", false);
      this.removed(result);
    });
  }
}
