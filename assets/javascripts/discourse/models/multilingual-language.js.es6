import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const MultilingualLanguage = EmberObject.extend();
const LanguagesPath = "/admin/multilingual/languages";

function getParams() {
  const searchParams = new URLSearchParams(window.location.search);
  let params = {};
  for (let pair of searchParams.entries()) {
    if (["query", "order", "ascending"].indexOf(pair[0]) > -1) {
      params[pair[0]] = pair[1];
    }
  }
  return params;
}

MultilingualLanguage.reopenClass({
  list(params = {}) {
    return ajax(LanguagesPath, {
      data: Object.assign(getParams(), params),
    })
      .then((result) => {
        return result.map((l) => MultilingualLanguage.create(l));
      })
      .catch(popupAjaxError);
  },

  save(languages, params = {}) {
    params = Object.assign(getParams(), params);
    let data = Object.assign({ languages }, params);
    return ajax(LanguagesPath, {
      method: "PUT",
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
    }).catch(popupAjaxError);
  },

  remove(locales) {
    return ajax(LanguagesPath, {
      method: "DELETE",
      data: Object.assign(getParams(), { locales }),
    }).catch(popupAjaxError);
  },
});

export default MultilingualLanguage;
