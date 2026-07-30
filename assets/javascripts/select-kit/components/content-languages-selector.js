import { classNames } from "@ember-decorators/component";
import MultiSelectComponent from "discourse/select-kit/components/multi-select";
import { selectKitOptions } from "discourse/select-kit/components/select-kit";

@classNames("content-languages-selector", "classNames")
@selectKitOptions({
  filterable: true,
})
export default class ContentLanguagesSelector extends MultiSelectComponent {
  allowAny = false;
  valueProperty = "locale";
  nameProperty = "name";
  initializeContentLanguges = true;

  didInsertElement() {
    super.didInsertElement(...arguments);

    if (
      !this.value &&
      this.initializeContentLanguges &&
      this.currentUser.content_languages.length
    ) {
      this.set("value", this.currentUser.content_languages[0].locale);
    }
  }
}
