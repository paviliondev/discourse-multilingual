import { action, computed, set } from "@ember/object";
import { schedule } from "@ember/runloop";
import { iconHTML } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import renderTag from "discourse/lib/render-tag";
import Composer from "discourse/models/composer";
import LanguageSwitcher from "../components/language-switcher";
import { isContentLanguage } from "../lib/multilingual";
import {
  discoveryParams,
  localeParam,
  removeParam,
} from "../lib/multilingual-route";
import {
  multilingualTagRenderer,
  multilingualTagTranslator,
} from "../lib/multilingual-tag";

export default {
  name: "multilingual",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const currentUser = container.lookup("service:current-user");

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

    withPluginApi((api) => {
      api.replaceTagRenderer(multilingualTagRenderer);

      discoveryParams.forEach((param) => {
        api.addDiscoveryQueryParam(param, {
          replace: true,
          refreshModel: true,
        });
      });

      api.onPageChange(() => removeParam(localeParam, { ctx: this }));

      api.addSaveableCustomFields("interface");

      api.modifyClass(
        "controller:preferences/interface",
        (Superclass) =>
          class extends Superclass {
            @action
            save() {
              if (!siteSettings.multilingual_content_languages_enabled) {
                return super.save();
              }

              let cl = this.model.custom_fields.content_languages;
              if (!cl || !cl.length) {
                this.set("model.custom_fields.content_languages", [""]);
              }

              return super.save().then(() => {
                const contentLanguages = this.site.content_languages;
                let rawUserLanguages =
                  this.model.custom_fields.content_languages;
                let userLanguages = [];

                if (typeof rawUserLanguages === "string") {
                  rawUserLanguages = [rawUserLanguages];
                }

                if (rawUserLanguages) {
                  userLanguages = rawUserLanguages.map((locale) => {
                    return contentLanguages.find((l) => l.locale === locale);
                  });
                }

                // See workaround above
                userLanguages = userLanguages.filter(
                  (l) => l && isContentLanguage(l.locale, siteSettings)
                );

                currentUser.set("content_languages", userLanguages);
              });
            }
          }
      );

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
        set(item, "label", multilingualTagTranslator(item.name));
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
        api.headerIcons.add("multilingual-language-switcher", LanguageSwitcher);
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
          schedule("afterRender", () => {
            document
              .querySelector(".tag-groups-container")
              ?.classList.add("content-tags");

            const nameInput = document.querySelector(
              ".tag-group-content h1 input"
            );
            if (nameInput) {
              nameInput.disabled = true;
            }

            const controls = document.querySelector(".content-tag-controls");
            const content = document.querySelector(".tag-group-content");
            if (controls && content) {
              content.append(controls);
            }
          });
        },
      });

      if (currentUser && currentUser.admin) {
        api.modifyClass("component:table-header-toggle", {
          pluginId: "discourse-multilingual",

          click(e) {
            if (e.target.closest(".toggle-all")) {
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
