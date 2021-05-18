import { get } from "@ember/object";
import { isRTL } from "discourse/lib/text-direction";
import { iconHTML } from "discourse-common/lib/icon-library";
import { escapeExpression } from "discourse/lib/utilities";
import { helperContext } from "discourse-common/lib/helpers";
import Category from "discourse/models/category";
import getURL from "discourse-common/lib/get-url";
import I18n from "I18n";

function translatedCategoryName(category) {
  let translatedName;
  let nameTranslations = get(category, "name_translations");
  if (nameTranslations) {
    translatedName = nameTranslations[I18n.currentLocale()];
  }
  return translatedName || get(category, "name");
}

function categoryStripe(color, classes) {
  let style = color ? "style='background-color: #" + color + ";'" : "";
  return "<span class='" + classes + "' " + style + "></span>";
}

function multilingualCategoryLinkRenderer(category, opts) {
  let descriptionText = get(category, "description_text");
  let restricted = get(category, "read_restricted");
  let url = opts.url
    ? opts.url
    : getURL(`/c/${Category.slugFor(category)}/${get(category, "id")}`);
  let href = opts.link === false ? "" : url;
  let tagName = opts.link === false || opts.link === "false" ? "span" : "a";
  let extraClasses = opts.extraClasses ? " " + opts.extraClasses : "";
  let color = get(category, "color");
  let html = "";
  let parentCat = null;
  let categoryDir = "";

  if (!opts.hideParent) {
    parentCat = Category.findById(get(category, "parent_category_id"));
  }

  const siteSettings = helperContext().siteSettings;
  const categoryStyle = opts.categoryStyle || siteSettings.category_style;
  if (categoryStyle !== "none") {
    if (parentCat && parentCat !== category) {
      html += categoryStripe(
        get(parentCat, "color"),
        "badge-category-parent-bg"
      );
    }
    html += categoryStripe(color, "badge-category-bg");
  }

  let classNames = "badge-category clear-badge";
  if (restricted) {
    classNames += " restricted";
  }

  let style = "";
  if (categoryStyle === "box") {
    style = `style="color: #${get(category, "text_color")};"`;
  }

  html +=
    `<span ${style} ` +
    'data-drop-close="true" class="' +
    classNames +
    '"' +
    (descriptionText ? 'title="' + descriptionText + '" ' : "") +
    ">";

  let categoryName = escapeExpression(translatedCategoryName(category));

  if (siteSettings.support_mixed_text_direction) {
    categoryDir = isRTL(categoryName) ? 'dir="rtl"' : 'dir="ltr"';
  }

  if (restricted) {
    html += `${iconHTML(
      "lock"
    )}<span class="category-name" ${categoryDir}>${categoryName}</span>`;
  } else {
    html += `<span class="category-name" ${categoryDir}>${categoryName}</span>`;
  }
  html += "</span>";

  if (opts.topicCount) {
    html += `<span class="topic-count" aria-label="${I18n.t(
      "category_row.topic_count",
      { count: opts.topicCount }
    )}">&times; ${opts.topicCount}</span>`;
  }

  if (href) {
    href = ` href="${href}" `;
  }

  extraClasses = categoryStyle ? categoryStyle + extraClasses : extraClasses;
  return `<${tagName} class="badge-wrapper ${extraClasses}" ${href}>${html}</${tagName}>`;
}

export { multilingualCategoryLinkRenderer, translatedCategoryName };
