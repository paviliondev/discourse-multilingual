/* eslint-disable ember/no-observers -- the connector tracks a legacy composer property */

import { schedule } from "@ember/runloop";
import { getOwner } from "discourse/lib/get-owner";

function setupSelector(isFirstPost, ctx) {
  ctx.set("showSelector", isFirstPost);

  if (isFirstPost) {
    schedule("afterRender", () => {
      const selector = document.querySelector(".content-languages-selector");
      const titleAndCategory = document.querySelector(".title-and-category");

      if (selector && titleAndCategory) {
        titleAndCategory.append(selector);
      }
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
