import { alias } from "@ember/object/computed";
import Component from "@ember/component";
import UploadMixin from "discourse/mixins/upload";
import { on } from "@ember/object/evented";

export default Component.extend(UploadMixin, {
  type: "yml",
  addDisabled: alias("uploading"),
  code: null,
  uploadType: 'language',
  message: null,
  
  _init: on("didInsertElement", function() {
    this.messageBus.subscribe("/uploads/" + this.type, msg => {
      console.log(msg);
      if (msg.uploaded) {
        this.setProperties({
          uploading: false,
          message: I18n.t('uploaded')
        });
        this.done(msg);
      } else if (msg.errors) {
        this.set('message', msg.errors[0]);
      }
      
      setTimeout(() => {
        this.set('message', null);
      }, 10000)
    });
  }),

  uploadDone() {
    // wait for message that uploaded file is processed.
  }
});
