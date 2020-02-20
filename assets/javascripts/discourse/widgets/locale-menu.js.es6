import { later } from "@ember/runloop";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { addParam, localeParam } from '../lib/multilingual-route';

export default createWidget("locale-menu", {
  tagName: "div.locale-menu",
  buildKey: () => "locale-menu",

  settings: {
    maxWidth: 320
  },
  
  defaultState() {
    return {
      availableLocales: this.site.interface_languages
    }
  },

  panelContents() {
    const { availableLocales } = this.state;
    const currentLocale = I18n.currentLocale();
    
    return h('ul', availableLocales.map(
      l => {
        let className = 'locale';
        
        if (l.code === currentLocale) {
          className += ' current';
        }
        
        return h('li', this.attach("link", {
          className,
          action: "changeLocale",
          actionParam: l.code,
          rawLabel: l.name
        }));
      }
    ));
  },
  
  changeLocale(locale) {
    addParam(localeParam, locale, { add_cookie: true, ctx: this });
  },

  html() {
    return this.attach("menu-panel", {
      maxWidth: this.settings.maxWidth,
      contents: () => this.panelContents()
    });
  },

  clickOutsideMobile(e) {
    const $centeredElement = $(document.elementFromPoint(e.clientX, e.clientY));
    if (
      $centeredElement.parents(".panel").length &&
      !$centeredElement.hasClass("header-cloak")
    ) {
      this.sendWidgetAction("toggleLocaleMenu");
    } else {
      const $window = $(window);
      const windowWidth = $window.width();
      const $panel = $(".menu-panel");
      $panel.addClass("animate");
      $panel.css("right", -windowWidth);
      const $headerCloak = $(".header-cloak");
      $headerCloak.addClass("animate");
      $headerCloak.css("opacity", 0);
      later(() => this.sendWidgetAction("toggleLocaleMenu"), 200);
    }
  },

  clickOutside(e) {
    if (this.site.mobileView) {
      this.clickOutsideMobile(e);
    } else {
      this.sendWidgetAction("toggleLocaleMenu");
    }
  }
});