import { later } from "@ember/runloop";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { addParam, localeParam } from "../lib/multilingual-route";
import I18n from "I18n";

export default createWidget("language-switcher-menu", {
  tagName: "div.language-switcher-menu",
  buildKey: () => "language-switcher-menu",

  settings: {
    maxWidth: 320,
  },

  defaultState() {
    return {
      available: this.site.interface_languages,
    };
  },

  panelContents() {
    const { available } = this.state;
    const currentLocale = I18n.currentLocale();

    return h(
      "ul",
      available.map((l) => {
        let className = "ls-language";

        if (l.locale === currentLocale) {
          className += " current";
        }

        return h(
          "li",
          this.attach("link", {
            className,
            action: "change",
            actionParam: l.locale,
            rawLabel: l.name,
          })
        );
      })
    );
  },

  change(locale) {
    addParam(localeParam, locale, { add_cookie: true, ctx: this });
  },

  html() {
    return this.attach("menu-panel", {
      maxWidth: this.settings.maxWidth,
      contents: () => this.panelContents(),
    });
  },

  clickOutsideMobile(e) {
    const $centeredElement = $(document.elementFromPoint(e.clientX, e.clientY));
    if (
      $centeredElement.parents(".panel").length &&
      !$centeredElement.hasClass("header-cloak")
    ) {
      this.sendWidgetAction("toggleLangugeSwitcherMenu");
    } else {
      const $window = $(window);
      const windowWidth = $window.width();
      const $panel = $(".menu-panel");
      $panel.addClass("animate");
      $panel.css("right", -windowWidth);
      const $headerCloak = $(".header-cloak");
      $headerCloak.addClass("animate");
      $headerCloak.css("opacity", 0);
      later(() => this.sendWidgetAction("toggleLangugeSwitcherMenu"), 200);
    }
  },

  clickOutside(e) {
    if (this.site.mobileView) {
      this.clickOutsideMobile(e);
    } else {
      this.sendWidgetAction("toggleLangugeSwitcherMenu");
    }
  },
});
