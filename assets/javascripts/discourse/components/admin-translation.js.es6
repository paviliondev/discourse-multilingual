import MultilingualTranslation from "../models/multilingual-translation";
import Component from "@ember/component";

export default Component.extend({
  tagName: "tr",
  classNames: "language",

  actions: {
    remove() {
      this.set("removing", true);

      MultilingualTranslation.remove(
        this.get("translation.locale"),
        this.get("translation.file_type")
      ).then((result) => {
        this.set("removing", false);
        this.removed(result);
      });
    },

    download() {
      MultilingualTranslation.download(
        this.get("translation.locale"),
        this.get("translation.file_type")
      );
    },
  },
});
