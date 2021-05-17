import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const MultilingualTranslation = EmberObject.extend();
const TranslationPath = "/admin/multilingual/translations";

MultilingualTranslation.reopenClass({
  list() {
    return ajax(TranslationPath).catch(popupAjaxError);
  },

  remove(code, type) {
    return ajax(TranslationPath, {
      method: "DELETE",
      data: {
        code,
        type,
      },
    }).catch(popupAjaxError);
  },

  download(code, type) {
    return ajax(TranslationPath + "/download", {
      data: {
        code,
        type,
      },
      xhrFields: {
        responseType: "blob",
      },
    });
  },
});

export default MultilingualTranslation;
