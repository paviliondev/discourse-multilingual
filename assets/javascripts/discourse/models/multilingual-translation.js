import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const TranslationPath = "/admin/multilingual/translations";

export default class MultilingualTranslation extends EmberObject {
  static list() {
    return ajax(TranslationPath).catch(popupAjaxError);
  }

  static remove(locale, file_type) {
    return ajax(TranslationPath, {
      method: "DELETE",
      data: {
        locale,
        file_type,
      },
    }).catch(popupAjaxError);
  }

  static download(locale, file_type) {
    return ajax(TranslationPath + "/download", {
      data: {
        locale,
        file_type,
      },
      xhrFields: {
        responseType: "blob",
      },
    });
  }
}
