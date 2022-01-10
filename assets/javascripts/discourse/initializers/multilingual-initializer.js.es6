import { withPluginApi } from "discourse/lib/plugin-api";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import { multilingualTagRenderer } from "../lib/multilingual-tag";
import { multilingualCategoryLinkRenderer } from "../lib/multilingual-category";
import {
  discoveryParams,
  localeParam,
  removeParam,
} from "../lib/multilingual-route";
import { isContentLanguage } from "../lib/multilingual";
import Composer from "discourse/models/composer";
import { iconHTML } from "discourse-common/lib/icon-library";
import renderTag from "discourse/lib/render-tag";
import { computed, set } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import I18n from "I18n";

export default {
  name: "multilingual",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");

    if (!siteSettings.multilingual_enabled) {
      return;
    }

    if (siteSettings.multilingual_content_languages_enabled) {
      Composer.serializeOnCreate(
        "content_language_tags",
        "content_language_tags"
      );
      Composer.serializeToTopic(
        "content_language_tags",
        "topic.content_language_tags"
      );
    }

    I18n.translate_tag = function (tag) {
      const translations = I18n.tag_translations || {};
      return translations[tag] || tag;
    };

    withPluginApi("0.8.36", (api) => {
      api.replaceTagRenderer(multilingualTagRenderer);
      api.replaceCategoryLinkRenderer(multilingualCategoryLinkRenderer);

      discoveryParams.forEach((param) => {
        api.addDiscoveryQueryParam(param, {
          replace: true,
          refreshModel: true,
        });
      });

      api.onPageChange(() => removeParam(localeParam, { ctx: this }));

      api.modifyClass("controller:preferences/interface", {
        pluginId: "discourse-multilingual",

        @discourseComputed()
        availableLocales() {
          return this.site.interface_languages.map((l) => {
            return {
              value: l.code,
              name: l.name,
            };
          });
        },

        @discourseComputed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push("custom_fields");
          return attrs;
        },

        actions: {
          save() {
            if (!siteSettings.multilingual_content_languages_enabled) {
              return this._super();
            }

            // jQuery ajax removes empty arrays. This is a workaround
            let cl = this.model.custom_fields.content_languages;
            if (!cl || !cl.length) {
              this.set("model.custom_fields.content_languages", [""]);
            }

            return this._super().then(() => {
              const contentLanguages = this.site.content_languages;
              let rawUserLanguages = this.model.custom_fields.content_languages;
              let userLanguages = [];

              if (typeof rawUserLanguages === "string") {
                rawUserLanguages = [rawUserLanguages];
              }

              if (rawUserLanguages) {
                userLanguages = rawUserLanguages.map((code) => {
                  return contentLanguages.find((l) => l.code === code);
                });
              }

              // See workaround above
              userLanguages = userLanguages.filter(
                (l) => l && isContentLanguage(l.code, siteSettings)
              );

              currentUser.set("content_languages", userLanguages);
            });
          },
        },
      });

      api.modifyClass("component:tag-drop", {
        pluginId: "discourse-multilingual",

        _prepareSearch(query) {
          const data = {
            q: query,
            filterForInput: true,
            limit: this.get("siteSettings.max_tag_search_results"),
          };

          this.searchTags("/tags/filter/search", data, this._transformJson);
        },
      });

      function tagDropCallback(item) {
        set(item, "label", I18n.translate_tag(item.name));
        return item;
      }

      function tagDropArrayCallback(content) {
        if (Array.isArray(content)) {
          return content.map((item) => tagDropCallback(item));
        } else {
          return tagDropCallback(content);
        }
      }

      api.modifyClass("component:tag-drop", {
        pluginId: "discourse-multilingual",

        modifyContent(content) {
          return tagDropArrayCallback(content);
        },
      });

      api.modifyClass("component:selected-name", {
        pluginId: "discourse-multilingual",

        label: computed("title", "name", function () {
          if (
            this.selectKit.options.headerComponent ===
            "tag-drop/tag-drop-header"
          ) {
            let item = tagDropCallback(this.item);
            return item.label || this.title || this.name;
          } else {
            return this._super(...arguments);
          }
        }),
      });

      api.addTagsHtmlCallback(
        function (topic) {
          const contentLanguageTags = topic.content_language_tags;

          if (
            !siteSettings.multilingual_content_languages_enabled ||
            !contentLanguageTags ||
            !contentLanguageTags[0]
          ) {
            return;
          }

          let html = '<div class="content-language-tags">';

          html += iconHTML("translate");

          contentLanguageTags.forEach((t) => {
            html +=
              renderTag(t, {
                contentLanguageTag: true,
                style: "content-language-tag",
              }) + " ";
          });

          html += "</div>";

          return html;
        },
        { priority: 100 }
      );

      if (
        !currentUser &&
        siteSettings.multilingual_guest_language_switcher === "header"
      ) {
        api.reopenWidget("header", {
          defaultState() {
            return jQuery.extend(this._super(...arguments), {
              languageSwitcherMenuVisible: false,
            });
          },

          toggleLangugeSwitcherMenu() {
            this.state.languageSwitcherMenuVisible = !this.state
              .languageSwitcherMenuVisible;
          },
        });

        api.decorateWidget("header-icons:before", (helper) => {
          return helper.attach("header-dropdown", {
            title: "user.locale.title",
            icon: "translate",
            iconId: "language-switcher-menu-button",
            action: "toggleLangugeSwitcherMenu",
            active:
              helper.widget.parentWidget.state.languageSwitcherMenuVisible,
          });
        });

        api.addHeaderPanel(
          "language-switcher-menu",
          "languageSwitcherMenuVisible",
          (attrs, state) => ({ attrs, state })
        );
      }

      api.modifyClass("route:tag-groups-edit", {
        pluginId: "discourse-multilingual",

        setupController(controller, model) {
          this._super(controller, model);

          if (model.content_language_group) {
            controller.setupContentTagControls();
          }
        },

        actions: {
          tagsChanged() {
            this.refresh();
          },
        },
      });

      api.modifyClass("controller:tag-groups-edit", {
        pluginId: "discourse-multilingual",

        setupContentTagControls() {
          scheduleOnce("afterRender", () => {
            $(".tag-groups-container").addClass("content-tags");
            $(".tag-group-content h1 input").prop("disabled", true);
            $(".content-tag-controls").appendTo(".tag-group-content");
          });
        },
      });

      if (currentUser && currentUser.admin) {
        api.modifyClass("component:table-header-toggle", {
          pluginId: "discourse-multilingual",

          click(e) {
            if ($(e.target).parents(".toggle-all").length) {
              return true;
            } else {
              return this._super(e);
            }
          },
        });
      }
    });
  },
};
