import { get } from "@ember/object";

function contentLanguageTag(tag) {
  if (!tag) return;
  const site = Discourse.Site.current();
  return site.content_languages.find(cl => cl.code == tag);
}

function contentLanguageTags(tags = []) {
  return tags.filter(t => contentLanguageTag(t));
}

function multilingualTagRenderer(tag, params) {
  params = params || {};
  const language = contentLanguageTag(tag);
    
  if (language && !params.language) return '';
  
  tag = Handlebars.Utils.escapeExpression(tag).toLowerCase();
  const translatedTag = I18n.translate_tag(tag);
  const visibleName = language ? language.name : translatedTag;
  
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
      path = `/tags/${tag}`;
    }
  }
  
  const href = path ? ` href='${Discourse.getURL(path)}' ` : "";

  if (Discourse.SiteSettings.tag_style || params.style) {
    classes.push(params.style || Discourse.SiteSettings.tag_style);
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

function addContentLanguageTags(topic, contentLanguageTags) {
  const tags = get(topic, 'tags') || [];
  const nonContentLanguageTags = tags.filter(t => !contentLanguageTag(t));
  topic.set('tags', nonContentLanguageTags.concat(contentLanguageTags));
}

function userContentLanguageCodes() {
  const currentUser = Discourse.User.current();
  if (!currentUser) return null;
  return currentUser.content_languages.map(l => l.code) || [];
}

function contentLanguageTagsFilter(tags, valueAttr = null, labelAttr = null, context) {
  return tags.filter(t => !contentLanguageTag(valueAttr ? t[valueAttr] : t))
    .map(t => {
      let translated = I18n.translate_tag(valueAttr ? t[valueAttr] : t);
      return labelAttr ? Object.assign(t, { [labelAttr]: translated }) : translated;
    });
}

export {
  contentLanguageTag,
  contentLanguageTags,
  contentLanguageTagsFilter,
  addContentLanguageTags,
  multilingualTagRenderer,
  userContentLanguageCodes
};