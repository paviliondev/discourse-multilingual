import { schedule } from "@ember/runloop";
import $ from "jquery";
import { getOwner } from "discourse-common/lib/get-owner";

function setupSelector(isFirstPost, ctx) {
  ctx.set("showSelector", isFirstPost);

  if (isFirstPost) {
    schedule("afterRender", () => {
      $(".content-languages-selector").appendTo(".title-and-category");
    });
  }
}

export default {
  shouldRender(_, ctx) {
    return (
      ctx.siteSettings.multilingual_enabled &&
      ctx.siteSettings.multilingual_content_languages_enabled
    );
  },

  setupComponent(attrs, ctx) {
    setupSelector(attrs.model.topicFirstPost, ctx);

    const controller = getOwner(this).lookup("service:composer");
    if (controller) {
      controller.addObserver("model.topicFirstPost", this, function () {
        if (this._state === "destroying") {
          return;
        }
        setupSelector(controller.get("model.topicFirstPost"), ctx);
      });
    }
  },
};
