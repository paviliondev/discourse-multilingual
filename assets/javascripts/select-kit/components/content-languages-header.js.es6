import DropdownSelectBoxHeaderComponent from "select-kit/components/dropdown-select-box/dropdown-select-box-header";
import computed from "ember-addons/ember-computed-decorators";

export default DropdownSelectBoxHeaderComponent.extend({
  @computed("selectKit.options.hasLanguages")
  btnClassName(hasLanguages) {
    return `btn no-text btn-icon ${hasLanguages ? "has-languages" : ""}`;
  },
});
