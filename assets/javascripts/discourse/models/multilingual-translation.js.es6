import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const MultilingualTranslation = EmberObject.extend();
const TranslationPath = "/admin/multilingual/translations";

MultilingualTranslation.reopenClass({
  list() {
    return ajax(TranslationPath).catch(popupAjaxError);
  },

  remove(locale, file_type) {
    return ajax(TranslationPath, {
      method: "DELETE",
      data: {
        locale,
        file_type,
      },
    }).catch(popupAjaxError);
  },

  download(locale, file_type) {
    return ajax(TranslationPath + "/download", {
      data: {
        locale,
        file_type,
      },
      xhrFields: {
        responseType: "blob",
      },
    });
  },
});

export default MultilingualTranslation;
