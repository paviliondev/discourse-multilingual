import { computed } from "@ember/object";
import DropdownSelectBoxHeaderComponent from "discourse/select-kit/components/dropdown-select-box/dropdown-select-box-header";

export default class ContentLanguagesHeader extends DropdownSelectBoxHeaderComponent {
  @computed("selectKit.options.hasLanguages")
  get btnClassName() {
    return `btn no-text btn-icon ${
      this.selectKit.options.hasLanguages ? "has-languages" : ""
    }`;
  }
}
