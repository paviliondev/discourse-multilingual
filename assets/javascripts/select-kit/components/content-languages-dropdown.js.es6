import DropdownSelectBox from "select-kit/components/dropdown-select-box";

export default DropdownSelectBox.extend({
  headerIcon: "translate",
  classNames: "content-languages-dropdown",
  rowComponent: "content-languages-row",
  headerComponent: "content-languages-header",
  valueAttribute: "code",
  nameProperty: "name",
  autofilterable: false,
  filterable: false,
  showFullTitle: false
});