import { alias } from "@ember/object/computed";
import Component from "@ember/component";
import UppyUploadMixin from "discourse/mixins/uppy-upload";
import { on } from "@ember/object/evented";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend(UppyUploadMixin, {
  type: "yml",
  addDisabled: alias("uploading"),
  elementId: "multilingual-uploader",
  preventDirectS3Uploads: true,
  classNameBindings: [":multilingual-uploader", "uploadType"],
  locale: null,
  message: null,

  _init: on("didInsertElement", function () {
    this.messageBus.subscribe("/uploads/" + this.type, (msg) => {
      if (msg.uploaded) {
        this.setProperties({
          uploading: false,
          message: I18n.t("uploaded"),
        });
        this.done();
      } else if (msg.errors) {
        this.set("message", msg.errors[0]);
      }

      setTimeout(() => {
        this.set("message", null);
      }, 10000);
    });
  }),

  @discourseComputed("uploadType")
  uploadUrl(uploadType) {
    return `/admin/multilingual/${uploadType}s`;
  },

  uploadDone() {
    // wait for message that uploaded file is processed.
  },

  validateUploadedFilesOptions() {
    return { skipValidation: true };
  },
});
