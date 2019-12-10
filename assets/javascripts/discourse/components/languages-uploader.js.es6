import { alias } from "@ember/object/computed";
import Component from "@ember/component";
import UploadMixin from "discourse/mixins/upload";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend(UploadMixin, {
  type: "yml",
  classNames: "languages-uploader",
  uploadUrl: "/admin/multilingual/languages",
  addDisabled: alias("uploading"),

  uploadDone() {
    if (this) {
      bootbox.alert(I18n.t("admin.multilingual.languages.upload_successful"));
      this.done();
    }
  }
});
