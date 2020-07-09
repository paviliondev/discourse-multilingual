import { isContentLanguage } from './multilingual';
import getURL from "discourse-common/lib/get-url";
import User from 'discourse/models/user';
import I18n from "I18n";

function multilingualTagRenderer(tag, params) {
  params = params || {};
  const clt = isContentLanguage(tag);
    
  if (clt && !params.contentLanguageTag) return '';
  
  tag = Handlebars.Utils.escapeExpression(tag).toLowerCase();
  const translatedTag = I18n.translate_tag(tag);
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
      path = `/tags/${tag}`;
    }
  }
  
  const href = path ? ` href='${getURL(path)}' ` : "";

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

export { multilingualTagRenderer };