import { isContentLanguage } from "./multilingual";
import { escapeExpression } from "discourse/lib/utilities";
import { helperContext } from "discourse-common/lib/helpers";
import getURL from "discourse-common/lib/get-url";
import User from "discourse/models/user";
import I18n from "I18n";

function multilingualTagRenderer(tag, params) {
  params = params || {};
  const siteSettings = helperContext().siteSettings;
  const clt = isContentLanguage(tag, siteSettings);

  if (clt && !params.contentLanguageTag) {
    return "";
  }

  tag = escapeExpression(tag).toLowerCase();
  const translatedTag = multilingualTagTranslator(tag);
  const visibleName = clt ? clt.name : translatedTag;

  const classes = ["discourse-tag"];
  const tagName = params.tagName || "a";
  let path;

  if (tagName === "a" && !params.noHref) {
    if ((params.isPrivateMessage || params.pmOnly) && User.current()) {
      const username = params.tagsForUser
        ? params.tagsForUser
        : User.current().username;
      path = `/u/${username}/messages/tags/${tag}`;
    } else {
      path = `/tag/${tag}`;
    }
  }

  const href = path ? ` href='${getURL(path)}' ` : "";

  if (siteSettings.tag_style || params.style) {
    classes.push(params.style || siteSettings.tag_style);
  }

  let val =
    "<" +
    tagName +
    href +
    " data-tag-name=" +
    tag +
    " class='" +
    classes.join(" ") +
    "'>" +
    visibleName +
    "</" +
    tagName +
    ">";

  if (params.count) {
    val += " <span class='discourse-tag-count'>x" + params.count + "</span>";
  }

  return val;
}

function multilingualTagTranslator(tag) {
  if (
    typeof I18n.tag_translations !== "undefined" &&
    I18n.tag_translations !== null &&
    typeof I18n.tag_translations[I18n.default.currentLocale()] !==
      "undefined" &&
    typeof I18n.tag_translations[I18n.default.currentLocale()][tag] !==
      "undefined"
  ) {
    return I18n.tag_translations[I18n.default.currentLocale()][tag];
  } else {
    return tag;
  }
}

export { multilingualTagRenderer, multilingualTagTranslator };
