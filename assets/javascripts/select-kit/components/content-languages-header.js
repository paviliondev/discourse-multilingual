/* eslint-disable discourse/discourse-common-imports, discourse/moved-packages-import-paths, simple-import-sort/imports */
import discourseComputed from "discourse-common/utils/decorators";
import DropdownSelectBoxHeaderComponent from "select-kit/components/dropdown-select-box/dropdown-select-box-header";

export default DropdownSelectBoxHeaderComponent.extend({
  @discourseComputed("selectKit.options.hasLanguages")
  btnClassName(hasLanguages) {
    return `btn no-text btn-icon ${hasLanguages ? "has-languages" : ""}`;
  },
});
