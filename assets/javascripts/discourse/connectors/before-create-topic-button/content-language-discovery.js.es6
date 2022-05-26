import { set } from "@ember/object";
import { isContentLanguage } from "../../lib/multilingual";
import {
  contentLanguageParam,
  getDiscoveryParam,
  getRouter,
} from "../../lib/multilingual-route";
import I18n from "I18n";

export default {
  shouldRender(attrs, ctx) {
    return (
      ctx.siteSettings.multilingual_enabled &&
      ctx.siteSettings.multilingual_content_languages_enabled &&
      ctx.siteSettings.multilingual_content_languages_topic_filtering_enabled &&
      (this.currentUser ||
        getRouter(ctx).currentRouteName.indexOf("categories") === -1)
    );
  },

  setupComponent(attrs, ctx) {
    const currentUser = ctx.get("currentUser");
    const site = ctx.get("site");

    let hasLanguages;
    let contentLanguages = currentUser
      ? currentUser.get("content_languages")
      : site.get("content_languages");

    if (!contentLanguages) {
      return;
    }

    if (currentUser) {
      hasLanguages =
        contentLanguages.filter((l) =>
          isContentLanguage(l.code, ctx.siteSettings)
        ).length > 0;

      if (!contentLanguages.some((l) => l.code === "set_content_language")) {
        contentLanguages.push({
          icon: "plus",
          code: "set_content_language",
          name: I18n.t("user.content_languages.set"),
        });
      }
    } else {
      hasLanguages = getDiscoveryParam(ctx, contentLanguageParam);

      contentLanguages.forEach((l) => {
        set(l, "classNames", "guest-content-language");
      });
    }

    ctx.setProperties({ contentLanguages, hasLanguages });
  },
};
