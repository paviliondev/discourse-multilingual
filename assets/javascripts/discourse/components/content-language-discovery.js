import Component from '@glimmer/component';
import { set } from "@ember/object";
import { inject as service } from "@ember/service";
import { isContentLanguage } from "../lib/multilingual";
import {
  contentLanguageParam,
  getDiscoveryParam
} from "../lib/multilingual-route";
import I18n from "I18n";

export default class ContentLanguageDiscovery extends Component {
  @service siteSettings;
  @service currentUser;
  @service router;
  @service site;

  get shouldRender() {
    return (
      this.siteSettings.multilingual_enabled &&
      this.siteSettings.multilingual_content_languages_enabled &&
      this.siteSettings.multilingual_content_languages_topic_filtering_enabled &&
      (this.currentUser ||
        this.router.currentRouteName.indexOf("categories") === -1)
    );
  };

  get contentLanguages() {
    let contentLangs = this.currentUser
      ? this.currentUser.content_languages
      : this.site.content_languages;

    if (contentLangs) {
      if (this.currentUser) {
        if (!contentLangs.some((l) => l.locale === "set_content_language")) {
          contentLangs.push({
            icon: "plus",
            locale: "set_content_language",
            name: I18n.t("user.content_languages.set"),
          });
        }
      } else {
        contentLangs.forEach((l) => {
          set(l, "classNames", "guest-content-language");
        });
      }
    }
    return contentLangs;
  };

  get hasLanguages() {
    let hasLangs;

    if (this.currentUser && this.contentLanguages) {
      hasLangs =
        this.contentLanguages.filter((l) =>
          isContentLanguage(l.locale, this.siteSettings)
        ).length > 0;
    } else {
      hasLangs = getDiscoveryParam(this, contentLanguageParam);
    }
    return hasLangs;
  }
};
