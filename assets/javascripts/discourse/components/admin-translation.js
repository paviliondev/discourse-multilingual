import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import MultilingualTranslation from "../models/multilingual-translation";

export default class AdminTranslation extends Component {
  @tracked removing = false;

  @action
  remove() {
    this.removing = true;

    MultilingualTranslation.remove(
      this.args.translation.locale,
      this.args.translation.file_type
    ).then(() => {
      this.removing = false;
      this.args.removed();
    });
  }

  @action
  download() {
    MultilingualTranslation.download(
      this.args.translation.locale,
      this.args.translation.file_type
    );
  }
}
