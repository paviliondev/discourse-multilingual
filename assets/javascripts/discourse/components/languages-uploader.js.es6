import { alias } from "@ember/object/computed";
import Component from "@ember/component";
import UploadMixin from "discourse/mixins/upload";
import discourseComputed from "discourse-common/utils/decorators";
import { on } from "@ember/object/evented";

export default Component.extend(UploadMixin, {
  type: "yml",
  classNames: "languages-uploader",
  uploadUrl: "/admin/multilingual/languages",
  addDisabled: alias("uploading"),
  
  _init: on("didInsertElement", function() {
    this.messageBus.subscribe("/uploads/" + this.type, msg => {
      if (msg.uploaded) {
        this.set('uploading', false);
        this.done();
      }
    });
  }),

  uploadDone() {
    // wait for message that uploaded file is processed.
  }
});
