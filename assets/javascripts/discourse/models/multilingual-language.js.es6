import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";

const MultilingualLanguage = EmberObject.extend();
const LanguagesPath = '/admin/multilingual/languages';

function getParams() {
  const searchParams = new URLSearchParams(window.location.search);
  let params = {};
  for (var pair of searchParams.entries()) {
    if (['filter', 'order', 'ascending'].indexOf(pair[0]) > -1) {
      params[pair[0]] = pair[1];
    }
  }
  return params;
}

MultilingualLanguage.reopenClass({
  all(params = {}) {
    return ajax(LanguagesPath, {
      data: Object.assign(getParams(), params)
    }).catch(popupAjaxError)
  },

  save(languages, params = {}) {
    let data = {
      languages: JSON.stringify(languages)
    };
    
    return ajax(LanguagesPath, {
      method: "PUT",
      data: Object.assign(data, Object.assign(getParams(), params))
    }).catch(popupAjaxError)
  },
  
  remove(codes) {
    return ajax(LanguagesPath, {
      method: "DELETE",
      data: Object.assign(getParams(), { codes })
    }).catch(popupAjaxError)
  }
});

export default MultilingualLanguage;

