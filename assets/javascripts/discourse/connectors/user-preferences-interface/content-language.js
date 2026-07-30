import { schedule } from "@ember/runloop";

export default {
  shouldRender(_, ctx) {
    return (
      ctx.siteSettings.multilingual_enabled &&
      ctx.siteSettings.multilingual_content_languages_enabled &&
      ctx.siteSettings.multilingual_content_languages_topic_filtering_enabled
    );
  },

  setupComponent() {
    schedule("afterRender", () => {
      const content = document.querySelector(
        ".control-group.content-languages"
      );
      const interfaceLocale = document.querySelector(
        ".control-group.pref-locale"
      );
      const textSize = document.querySelector(".control-group.text-size");
      const form = document.querySelector(".user-preferences form");

      if (content && textSize && form && content.parentElement !== form) {
        form.prepend(content);
      }

      if (
        content &&
        interfaceLocale &&
        content.nextElementSibling !== interfaceLocale
      ) {
        content.after(interfaceLocale);
      }
    });
  },
};
