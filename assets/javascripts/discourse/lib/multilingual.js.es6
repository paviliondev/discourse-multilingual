import { get } from "@ember/object";

function languageTag(tag) {
  if (!tag) return;
  const site = Discourse.Site.current();
  return site.content_languages.find(cl => cl.code == tag);
}

function languageTags(tags = []) {
  return tags.filter(t => languageTag(t));
}

function languageTagRenderer(tag, params) {
  params = params || {};
  const language = languageTag(tag);
    
  if (language && !params.language) return '';
  
  tag = Handlebars.Utils.escapeExpression(tag).toLowerCase();
  const visibleName = language ? language.name : tag;
  
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

function addLanguageTags(topic, languageTags) {
  const tags = get(topic, 'tags') || [];
  const nonLanguageTags = tags.filter(t => !languageTag(t));
  topic.set('tags', nonLanguageTags.concat(languageTags));
}

function userContentLanguageCodes() {
  const currentUser = Discourse.User.current();
  if (!currentUser) return null;
  return currentUser.content_languages.map(l => l.code) || [];
}

export {
  languageTag,
  languageTags,
  languageTagRenderer,
  addLanguageTags,
  userContentLanguageCodes
};